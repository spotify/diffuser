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

/**
 * A Source takes a side-effecting function which it will call when it wants to emit an event. When
 * given such a function, it will return a {@link Disposable} which can be called when the consumer
 * no longer wants to receive events.
 *
 * @param <A> - The type of event emitted by this Source
 */
public interface Source<A> {

  /**
   * @param effect: a side-effecting function which it will call whenever it wants to emit an event.
   * @return A {@link Disposable} which can be called when this connection should be torn down.
   */
  Disposable connect(Effect<A> effect);
}
