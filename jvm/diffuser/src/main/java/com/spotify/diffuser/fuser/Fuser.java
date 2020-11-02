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

package com.spotify.diffuser.fuser;

import com.spotify.diffuser.Effect;
import com.spotify.diffuser.Function;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * A Fuser&lt;A&gt; is a stream of events of type A. It has three static functions for constructing
 * and composing Fusers: - {@link #from(Source)}: create a Fuser by wrapping something which
 * produces events. - {@link #fromAll(Fuser[])}: merge multiple Fusers. supplied to connect. This
 * returns a {@link Disposable} which allows you to stop listening. - {@link #extract(Function,
 * Fuser)}: apply a function to every event emitted by a Fuser.
 *
 * <p>Once constructed, {@link #connect(Effect)} can be called. This allows you to start listening
 * to events from the Fuser. This returns a {@link Disposable} which allows you to stop listening.
 *
 * @param <A> The Type of events emitted by this Fuser
 */
public final class Fuser<A> {

  private final Source<A> source;

  private Fuser(Source<? extends A> source) {
    this.source = (Source<A>) source;
  }

  /**
   * Create a Fuser given {@link Source}s
   *
   * @param children - The sources of events for this Fuser
   */
  public Fuser(Fuser<? extends A>... children) {
    final List<Fuser<? extends A>> asList = Arrays.asList(children);
    final List<Fuser<A>> fusers = upcast(asList);
    this.source = sourceFrom(fusers);
  }

  /**
   * Create a new Fuser given a collection of Fusers of the same type. The new Fuser will emit all
   * events emitted by its children. Connecting to the new Fuser will connect all of the children,
   * and disposing said connection disposes all child connections.
   *
   * @param children The collection of Fusers to merge
   */
  public Fuser(Collection<Fuser<? extends A>> children) {
    final List<Fuser<A>> fusers = upcast(children);
    this.source = sourceFrom(fusers);
  }

  /**
   * Create a Fuser from a {@link Source}.
   *
   * @param source the source which will supply this Fuser with events once connected.
   * @param <A> the type of events emitted by this fuser
   * @return A Fuser which wraps a {@link Source}
   */
  public static <A> Fuser<A> from(Source<? extends A> source) {
    return new Fuser<>(source);
  }

  /**
   * Create a new Fuser given a collection of Fusers of the same type. The new Fuser will emit all
   * events emitted by its children. Connecting to the new Fuser will connect all of the children
   * and disposing said connection disposes all child connections.
   *
   * @param children The collection of Fusers to merge
   * @param <A> The type of events emitted by this Fuser
   * @return a new Fuser which wraps a sequence of Fusers
   */
  public static <A> Fuser<A> fromAll(Collection<Fuser<A>> children) {
    return new Fuser(children);
  }

  /**
   * Create a new Fuser given a sequence of Fusers of the same type. The new Fuser will emit all
   * events emitted by its children. Connecting to the new Fuser will connect all of the children
   * and disposing said connection disposes all child connections.
   *
   * @param children The collection of Fusers to merge
   * @param <A> The type of events emitted by this Fuser
   * @return a new Fuser which wraps a sequence of Fusers
   */
  @SafeVarargs
  public static <A> Fuser<A> fromAll(Fuser<? extends A>... children) {
    return new Fuser(children);
  }

  /**
   * Apply a function to each event emitted by a Fuser.
   *
   * <p>We intentionally do not provide other combinators than extract, like `flatMap`, `filter`, or
   * `reduce`. The Fuser is designed for aggregating UI-events and should be placed in the UI-layer
   * of an application. `extract` is primarily intended for converting from Android.View types to
   * types in your domain. Any additional interpretation of events should be placed outside of the
   * Fuser and outside the UI-layer.
   *
   * @param transformation the function to be applied to each event emitted by the `fuser` parameter
   * @param fuser the fuser to which the `transformation` function should be applied
   * @param <A> The type you are transforming from
   * @param <B> The type you are transforming into
   * @return A new Fuser of type B
   */
  public static <A, B> Fuser<B> extract(Function<A, B> transformation, Fuser<A> fuser) {
    return from(
        dispatch ->
            fuser.connect(
                a -> {
                  final B b = transformation.apply(a);
                  dispatch.run(b);
                }));
  }

  /**
   * Emit a constant for every event emitted by a Fuser.
   *
   * @param constant the constant to be emitted for each event emitted by the `fuser` parameter
   * @param fuser the fuser to which the `transformation` function should be applied
   * @param <A> The type you are transforming from
   * @param <B> The type you are transforming into
   * @return A new Fuser of type B
   */
  public static <A, B> Fuser<B> extractConstant(B constant, Fuser<A> fuser) {
    return from(dispatch -> fuser.connect(a -> dispatch.run(constant)));
  }

  /**
   * Apply a function to every event emitted by a {@link Fuser}. The event is dropped if the
   * function returns null.
   *
   * @param transformation: the function to be applied to each event emitted by the fuser. The event
   *     will be dropped if this function returns null.
   * @param fuser: the fuser to which the `transformation` function should be applied
   * @param <A> The type you are transforming from, if tranformed to null it will be dropped.
   * @param <B> The type you are transforming into
   * @return A {@link Fuser} which drops all events which are transformed into null.
   */
  public static <A, B> Fuser<B> extractUnlessNull(Function<A, B> transformation, Fuser<A> fuser) {
    return from(
        dispatch ->
            fuser.connect(
                a -> {
                  final B b = transformation.apply(a);
                  if (b != null) {
                    dispatch.run(b);
                  }
                }));
  }

  /**
   * Start observing the events emitted by a Fuser. Remember to call dispose() on the disposable
   * returned when connecting. Otherwise you may leak resources.
   *
   * @param effect the side-effect which should be performed when the Fuser emits an event
   * @return a disposable which can be called to unsubscribe from the Fuser's events
   */
  public Disposable connect(Effect<A> effect) {
    final AtomicBoolean isDisposed = new AtomicBoolean(false);

    final Effect<A> safeEffect =
        value -> {
          if (!isDisposed.get()) {
            effect.run(value);
          }
        };

    final Disposable disposable = source.connect(safeEffect);

    return () -> {
      isDisposed.set(true);
      disposable.dispose();
    };
  }

  private static <A> List<Fuser<A>> upcast(Collection<Fuser<? extends A>> children) {
    final List<Fuser<A>> fusers = new ArrayList<>();
    synchronized (children) {
      for (Fuser<? extends A> child : children) {
        @SuppressWarnings("unchecked")
        final Fuser<A> upCast = (Fuser<A>) child;
        fusers.add(upCast);
      }
    }
    return fusers;
  }

  private static <A> Source<A> sourceFrom(List<Fuser<A>> fusers) {
    return effect -> {
      final List<Disposable> disposables = new ArrayList<>();
      for (final Fuser<A> fuser : fusers) {
        final Disposable disposable = fuser.connect(effect);
        disposables.add(disposable);
      }
      return () -> {
        synchronized (disposables) {
          for (final Disposable disposable : disposables) {
            disposable.dispose();
          }
          disposables.clear();
        }
      };
    };
  }
}
