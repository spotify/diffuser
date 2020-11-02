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

package com.spotify.diffuser.fuser

import com.spotify.diffuser.Effect

class AfterDisposeEmittingSource: Source<Int> {

    var output: Effect<Int>? = null
    var isDisposed = false

    fun emit(n: Int) {
        // Will try to emit even if disposed
        output?.run(n)
    }

    override fun connect(effect: Effect<Int>): Disposable {
        if (isDisposed) throw IllegalStateException("This source can only connect once")

        output = effect
        return Disposable {
            isDisposed = true
        }
    }
}

class DisposableSource: Source<Int> {

    var isDisposed = false

    override fun connect(effect: Effect<Int>): Disposable {
        if (isDisposed) throw IllegalStateException("This source can only connect once")
        return Disposable {
            isDisposed = true
        }
    }
}

class TestSource: Source<Int> {

    var outputs = mutableSetOf<Effect<Int>>()

    fun emit(n: Int) {
        // Will try to emit even if disposed
        outputs.forEach {
            it.run(n)
        }
    }

    override fun connect(effect: Effect<Int>): Disposable {
        outputs.add(effect)
        return Disposable {
            outputs.remove(effect)
        }
    }
}
