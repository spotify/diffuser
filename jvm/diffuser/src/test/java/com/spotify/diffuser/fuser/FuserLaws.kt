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

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * Shared tests that verifies the laws that all Fusers are expected to conform to.
 */
abstract class FuserLaws {

    abstract fun identityFuser(source: Source<Int>): Fuser<Int>

    @Test
    fun `Values are dispatched in order`() {
        // events after connect are sent in order
        val source = TestSource()
        val fuser = identityFuser(source)
        val output = mutableListOf<Int>()

        val disposable = fuser.connect { output.add(it) }
        source.emit(1)
        source.emit(2)
        source.emit(3)
        disposable.dispose()

        assertEquals(listOf(1, 2, 3), output)
    }

    @Test
    fun `Values are only dispatched after connect()`() {
        // events after connect are dispatched
        val source = TestSource()
        val fuser = identityFuser(source)
        val output = mutableListOf<Int>()

        source.emit(1)
        val disposable = fuser.connect { output.add(it) }
        source.emit(2)
        source.emit(3)
        disposable.dispose()

        assertEquals(listOf(2, 3), output)
    }

    @Test
    fun `Values are not dispatched after dispose()`() {
        val source = AfterDisposeEmittingSource()
        val fuser = identityFuser(source)
        val output = mutableListOf<Int>()

        val disposable = fuser.connect { output.add(it) }
        source.emit(1)
        source.emit(2)
        disposable.dispose()
        source.emit(3)

        assertEquals(listOf(1, 2), output)
    }

    @Test
    fun `Calling dispose() disposes the source`() {
        val source = DisposableSource()
        val fuser = identityFuser(source)

        val disposable = fuser.connect {}

        assertFalse(source.isDisposed)
        disposable.dispose()
        assertTrue(source.isDisposed)
    }

    @Test
    fun `Can be connected to multiple times`() {
        val source = TestSource()
        val fuser = identityFuser(source)

        val output1 = mutableListOf<Int>()
        val connection1 = fuser.connect { output1.add(it) }

        val output2 = mutableListOf<Int>()
        val connection2 = fuser.connect { output2.add(it) }

        val input = listOf(1, 2, 3)
        input.forEach { source.emit(it) }

        connection1.dispose()
        connection2.dispose()

        assertEquals(input, output1)
        assertEquals(input, output2)
    }

    @Test
    fun `Connections can be disposed independently`() {
        val source = TestSource()
        val fuser = identityFuser(source)

        val output1 = mutableListOf<Int>()
        val connection1 = fuser.connect { output1.add(it) }

        val output2 = mutableListOf<Int>()
        val connection2 = fuser.connect { output2.add(it) }

        source.emit(1)
        source.emit(2)
        connection1.dispose()
        source.emit(3)
        connection2.dispose()

        assertEquals(listOf(1, 2), output1)
        assertEquals(listOf(1, 2, 3), output2)
    }
}
