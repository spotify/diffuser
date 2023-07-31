/*
 * Copyright (c) 2019 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package com.spotify.diffuser.diffuser;

import com.spotify.diffuser.Effect;
import com.spotify.diffuser.Function;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.concurrent.atomic.AtomicReference;

/**
 * A Diffuser wraps a side-effecting function.
 *
 * <p>When {@link #run(Object)} is called on a Diffuser, it will decide if it should forward the
 * supplied arguments to its side-effecting function. E.g., Diffusers created using {@link
 * #into(Effect)} and {@link #intoAll(Diffuser[])} only forward calls when the input value is
 * different from the previous value, or if {@link #run(Object)} was called for the first time.
 * {@link #intoWhen(DidChange, Effect)} can be to specify more nuanced caching. {@link
 * #intoAlways(Effect)} will always run its function.
 *
 * <p>Diffusers can be combined to orchestrate groups of side-effects. E.g., {@link
 * #intoAll(Diffuser[])} can be used to merge a list of Diffusers with the same input type, and
 * {@link #map(Function, Diffuser)} can be used to change a Diffuser's input type
 *
 * @param <A> The type of values that this Diffuser can be {@link #run(Object)} with.
 */
public final class Diffuser<A> {
  private final Effect<A> effect;

  private Diffuser(DidChange<A> didChange, Effect<A> sideEffect) {
    final AtomicReference<A> cache = new AtomicReference<>();

    this.effect =
        value -> {
          if (didChange.test(cache.get(), value)) {
            sideEffect.run(value);
          }
          cache.set(value);
        };
  }

  private Diffuser(Effect<A> effect) {
    this.effect = effect;
  }

  /**
   * Merge a list of Diffusers with the same input type. No additional caching is added, All
   * Diffusers will be called whenever {@link #run(Object)} is called.
   *
   * @param children: the list of Diffusers to merge
   */
  public Diffuser(Collection<Diffuser<A>> children) {
    this(Diffuser::notEqual, effectFromChildren(children));
  }

  private static <A> Effect<A> effectFromChildren(Collection<Diffuser<A>> children) {
    List<Diffuser<A>> copiedChildren = new ArrayList(children);
    return newValue -> {
      for (Diffuser<A> diffuser : copiedChildren) {
        diffuser.run(newValue);
      }
    };
  }

  /**
   * Merge a list of Diffusers with the same input type. No additional caching is added, All
   * Diffusers will be called whenever {@link #run(Object)} is called.
   *
   * @param children: the list of Diffusers to merge
   */
  @SafeVarargs
  public Diffuser(Diffuser<A>... children) {
    this(Arrays.asList(children));
  }

  /**
   * Run the side-effects associated with this Diffuser if it hasn't been run before, or if the
   * newValue parameter is classified as different from the last time it ran.
   *
   * <p>The value you supply will be used as the cache the next time this function is called.
   *
   * @param newValue: The value to execute side effects based on.
   */
  public synchronized void run(A newValue) {
    effect.run(newValue);
  }

  /**
   * Create a Diffuser which always executes its side-effect regardless of the value.
   *
   * <p>This function is useful as a building block for more complex Diffusers, but it is unlikely
   * that you would use it its own. Consider using {@link #into(Effect)} instead.
   *
   * @param effect: The side-effect which should be performed when {@link #run(Object)} is called on
   *     this Diffuser.
   * @param <A> The type of the values received by this Diffuser.
   * @return A Diffuser which always executes its side-effect when given a value.
   */
  public static <A> Diffuser<A> intoAlways(Effect<A> effect) {
    return new Diffuser<>(effect);
  }

  /**
   * Add an additional layer of caching to an existing Diffuser.
   *
   * <p>This function is useful as a building block for more complex Diffusers, but it is unlikely
   * that you would use it on its own. Consider using {@link #into(Effect)} instead.
   *
   * @param didChange: a function which returns determines if the side-effect should be executed
   *     given the previous value and the current value that the diffuser is {@link #run(Object)}
   *     with. if {@link #run(Object)} is called for the first time, the side-effect will be
   *     executed regardless, and this function will not be run.
   * @param diffuser: the diffuser to wrap
   * @param <A> The type of the values received by this Diffuser.
   * @return a diffuser which wraps the diffuser parameter with an additional caching policy.
   */
  public static <A> Diffuser<A> intoWhen(DidChange<A> didChange, Diffuser<A> diffuser) {
    return new Diffuser<>(didChange, diffuser::run);
  }

  /**
   * Create a Diffuser by wrapping a side-effecting function with a caching layer.
   *
   * <p>This function is useful as a building block for more complex Diffusers, but it is unlikely
   * that you would use it on its own. Consider using {@link #into(Effect)} instead.
   *
   * @param didChange: A function which returns determines if the side-effect should be executed
   *     given the previous value and the current value that the Diffuser is {@link #run(Object)}
   *     with. If {@link #run(Object)} is called for the first time, the side-effect will be
   *     executed regardless, and this function will not be run.
   * @param effect: The side-effect to execute
   * @param <A>: The type of the values received by this Diffuser.
   * @return A Diffuser which wraps the diffuser parameter with an additional caching policy.
   */
  public static <A> Diffuser<A> intoWhen(DidChange<A> didChange, Effect<A> effect) {
    return new Diffuser<>(didChange, effect);
  }

  /**
   * Create a Diffuser from a side-effecting function. The Diffuser will cache its inputs using the
   * input type's definition of equality.
   *
   * @param effect: a side-effect which should be run when the input changes
   * @param <A>: The type of the values received by this Diffuser.
   * @return A Diffuser which runs side-effect when its input changes.
   */
  public static <A> Diffuser<A> into(Effect<A> effect) {
    return new Diffuser<>(Diffuser::notEqual, effect);
  }

  /**
   * Create a Diffuser which will only run its side-effecting function once, when it receives its
   * first value.
   *
   * @param effect: a side-effect which should be run once.
   * @param <A>: The type of the values received by this Diffuser.
   * @return A Diffuser which only runs its side-effect once the first time {@link #run(Object)} is
   *     called on it.
   */
  public static <A> Diffuser<A> intoOnce(Effect<A> effect) {
    return new Diffuser<>((a, b) -> false, effect);
  }

  /**
   * Merge a list of Diffusers parameterized by the same type. No additional caching is added, All
   * the Diffusers will be called whenever {@link #run(Object)} is called.
   *
   * @param children: the list of Diffusers to merge
   * @param <A> The input type of the returned Diffuser
   * @return A merged Diffuser which forwards any values it is {@link #run(Object)} with to all its
   *     children.
   */
  public static <A> Diffuser<A> intoAll(Collection<Diffuser<A>> children) {
    return new Diffuser<>(children);
  }

  /**
   * Merge a list of Diffusers parameterized by the same type. No additional caching is added, All
   * the Diffusers will be called whenever {@link #run(Object)} is called.
   *
   * @param children: the list of Diffusers to merge
   * @param <A> The input type of the returned Diffuser
   * @return A merged Diffuser which forwards any values it is {@link #run(Object)} with to all its
   *     children.
   */
  @SafeVarargs
  public static <A> Diffuser<A> intoAll(Diffuser<A>... children) {
    return intoAll(Arrays.asList(children));
  }

  /**
   * Change the input type of a Diffuser using a transformation function. The transformation
   * function will always be run.
   *
   * @param transform: The function which determines how the Diffuser parameters input should be
   *     changed.
   * @param diffuser: The Diffuser you wish to change the input type of.
   * @param <A> The type of the Diffuser being converted
   * @param <B> The desired input type of the returned Diffuser
   * @return A Diffuser with a transformed input type.
   */
  public static <A, B> Diffuser<A> map(Function<A, B> transform, Diffuser<B> diffuser) {
    return new Diffuser<>(it -> diffuser.run(transform.apply(it)));
  }

  private static <A> boolean notEqual(A a, A b) {
    return !Objects.equals(b, a);
  }
}
