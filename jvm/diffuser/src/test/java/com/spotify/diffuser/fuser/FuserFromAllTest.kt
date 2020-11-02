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

import com.spotify.diffuser.GenUtils.integerLists
import com.spotify.diffuser.fuser.Fuser.from
import com.spotify.diffuser.fuser.Fuser.fromAll
import org.junit.Assert.assertEquals
import org.junit.Test
import org.quicktheories.WithQuickTheories
import java.util.Random

class FuserFromAllTest : WithQuickTheories {

    class Laws : FuserLaws() {
        override fun identityFuser(source: Source<Int>) = fromAll(listOf<Fuser<Int>>(from(source)))
    }

    @Test
    fun `fromAll() combines multiple Fusers into one`() {
        // fromAll(fusers).connect { output(it) } == fusers.map { fuser -> fuser.connect { output(it) } }

        qt().forAll(integerLists, integers().between(0, 10), longs().all())
                .check { input, numberOfFusers, seed ->
                    val rnd = Random(seed)
                    val sources = (1..numberOfFusers).map { TestSource() }
                    val fusers = sources.map { source -> from(source) }

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    // LHS: fromAll(fusers).connect { output(it) }
                    val disposableLhs = fromAll(fusers).connect { outputLhs.add(it) }

                    // RHS: fusers.map { fuser -> fuser.connect { output(it) }
                    val disposablesRhs = fusers.map { fuser -> fuser.connect { outputRhs.add(it) } }

                    input.forEach { n ->
                        if (sources.isNotEmpty()) {
                            val randomIndex = Math.abs(rnd.nextInt(sources.size))
                            val source = sources[randomIndex]
                            source.emit(n)
                        }
                    }

                    disposableLhs.dispose()
                    disposablesRhs.forEach { it.dispose() }

                    assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }

    @Test
    fun `fromAll() disposes all child Fusers when disposed`() {
        qt().forAll(integers().between(0, 10))
                .check { numberOfFusers ->
                    val sources = (1..numberOfFusers).map { DisposableSource() }
                    val fusers = sources.map { source -> from(source) }

                    val disposable = fromAll(fusers).connect {}
                    disposable.dispose()

                    sources.all { it.isDisposed }
                }
    }
}
