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

import com.spotify.diffuser.GenUtils
import com.spotify.diffuser.GenUtils.integerLists
import com.spotify.diffuser.GenUtils.transformers
import com.spotify.diffuser.fuser.Fuser.extract
import com.spotify.diffuser.fuser.Fuser.extractConstant
import com.spotify.diffuser.fuser.Fuser.extractUnlessNull
import com.spotify.diffuser.fuser.Fuser.from
import org.junit.Assert
import org.junit.Test
import org.quicktheories.WithQuickTheories

class FuserExtractTest : WithQuickTheories {
    class Laws : FuserLaws() {
        override fun identityFuser(source: Source<Int>) = extract({ it }, from(source))
    }

    @Test
    fun `extract() conforms to identity law`() {
        // identity
        // extract(id, fuser) == fuser
        qt().forAll(GenUtils.integerLists)
                .check { input ->
                    val source = TestSource()
                    val fuser = from(source)

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    // LHS: extract(id, fuser)
                    val fuserLhs = extract({ it }, fuser)

                    // RHS: fuser
                    val fuserRhs = fuser

                    val disposableLhs = fuserLhs.connect { outputLhs.add(it) }
                    val disposableRhs = fuserRhs.connect { outputRhs.add(it) }
                    input.forEach { source.emit(it) }
                    disposableLhs.dispose()
                    disposableRhs.dispose()

                    Assert.assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }


    @Test
    fun `extract() conforms to associativity law`() {
        // is associative
        // extract(f, extract(g, fuser)) == extract({ f(g(it)) }, fuser)
        qt().forAll(integerLists, transformers, transformers)
                .check { input, f, g ->
                    val source = TestSource()
                    val fuser = from(source)

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    // LHS: extract(f, extract(g, fuser))
                    val fuserLhs = extract(f, extract(g, fuser))

                    // RHS: extract({ f(g(it)) }, fuser)
                    val fuserRhs = extract({ f.apply(g.apply(it)) }, fuser)

                    val disposableLhs = fuserLhs.connect { outputLhs.add(it) }
                    val disposableRhs = fuserRhs.connect { outputRhs.add(it) }
                    input.forEach { source.emit(it) }
                    disposableLhs.dispose()
                    disposableRhs.dispose()

                    Assert.assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }

    @Test
    fun `extract() applies transformation to all values`() {
        // applies transformation
        // extract(f, fuser).connect { output(it) } == fuser.connect { output(f(it)) }
        qt().forAll(integerLists, transformers)
                .check { input, f ->
                    val source = TestSource()
                    val fuser = from(source)

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    // LHS: extract(f, fuser).connect { output(it) }
                    val disposableLhs = extract(f, fuser).connect { outputLhs.add(it) }

                    // RHS: fuser.connect { output(f(it)) }
                    val disposableRhs = fuser.connect { outputRhs.add(f.apply(it)) }

                    input.forEach { source.emit(it) }
                    disposableLhs.dispose()
                    disposableRhs.dispose()

                    Assert.assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }

    @Test
    fun `extractConstant() is the same as extract() with a constant-returning function`() {
        // extractConstant(constant, fuser) == extract({ constant }, fuser)
        qt().forAll(integerLists, integers().all())
                .check { input, constant ->
                    val source = TestSource()
                    val fuser = from(source)

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    val disposableLhs = extractConstant(constant, fuser)
                            .connect { outputLhs.add(it) }

                    val disposableRhs = extract({ constant }, fuser).connect { outputRhs.add(it) }

                    input.forEach { source.emit(it) }
                    disposableLhs.dispose()
                    disposableRhs.dispose()

                    Assert.assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }

    @Test
    fun `extractUnlessNull() drops all null values`() {
        val lists = integerLists
                .map { list -> list.map { n -> n.rem(4) } }
        qt().forAll(lists, integers().all())
                .check { input, _ ->
                    val source = TestSource()
                    val fuser = from(source)

                    val output = mutableListOf<Int>()

                    val newFuser: Fuser<Int> = extractUnlessNull(
                            { if (it == 3) null else it },
                            fuser
                    )
                    val disposable = newFuser.connect { output.add(it) }

                    input.forEach { source.emit(it) }
                    disposable.dispose()

                    val expectedOutput = input.filterNot { it == 3 }
                    Assert.assertEquals(expectedOutput, output)
                    expectedOutput == output
                }
    }
}
