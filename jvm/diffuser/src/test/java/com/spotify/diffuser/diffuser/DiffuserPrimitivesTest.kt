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

package com.spotify.diffuser.diffuser

import com.spotify.diffuser.GenUtils.alwaysChanged
import com.spotify.diffuser.GenUtils.didChanges
import com.spotify.diffuser.GenUtils.integerLists
import com.spotify.diffuser.GenUtils.transformers
import com.spotify.diffuser.GenUtils.zip
import com.spotify.diffuser.diffuser.Diffuser.into
import com.spotify.diffuser.diffuser.Diffuser.intoAll
import com.spotify.diffuser.diffuser.Diffuser.intoAlways
import com.spotify.diffuser.diffuser.Diffuser.intoWhen
import com.spotify.diffuser.diffuser.Diffuser.map
import junit.framework.TestCase.assertEquals
import org.junit.Assert
import org.junit.Test
import org.quicktheories.WithQuickTheories

class DiffuserPrimitivesTest: WithQuickTheories {

    private fun generateExpectedChanges(input: List<Int>, didChange: DidChange<Int>): List<Int> {
        val output = mutableListOf<Int>()

        // Always include first from input, as there is no cache when first change happens
        input.firstOrNull()?.let { output.add(it) }

        for ((a, b) in input.windowed(2)) {
            if (didChange.test(a, b)) output.add(b)
        }

        return output
    }

    @Test
    fun `intoAlways() sends all values in order`() {
        // run(a); run(b); ... run(n); --> ab...n
        qt().forAll(integerLists)
                .check { input ->
                    val output = mutableListOf<Int>()

                    val diffuser = intoAlways<Int> { output.add(it) }

                    input.forEach(diffuser::run)

                    return@check input == output
                }
    }

    @Test
    fun `intoWhen(alwaysChanged, intoAlways()) is the same thing as intoAlways()`() {
        // intoWhen({ true }, intoAlways(eff)) == intoAlways(eff)
        effectsBehaveTheSame(
                formula(
                        lhs = { eff -> intoWhen(alwaysChanged, intoAlways(eff)) },
                        rhs = { eff -> intoAlways(eff) }
                )
        )
    }

    @Test
    fun `intoWhen() runs effect when value changes`() {
        //                             run(a);                 --> a
        //
        // !diff(a, b)              => run(a); run(b);         --> a
        //  diff(a, b)              => run(a); run(b);         --> ab
        //
        // !diff(a,b) && !diff(b,c) => run(a); run(b); run(c); --> a
        //  diff(a,b) && !diff(b,c) => run(a); run(b); run(c); --> ab
        // !diff(a,b) &&  diff(b,c) => run(a); run(b); run(c); --> ac
        //  diff(a,b) &&  diff(b,c) => run(a); run(b); run(c); --> abc
        qt().forAll(integerLists, didChanges)
                .check { input, didChange ->
                    val outputLhs = mutableListOf<Int>()
                    val diffuserLhs = intoWhen(didChange, intoAlways { outputLhs.add(it) })

                    val outputRhs = generateExpectedChanges(input, didChange)

                    input.forEach { diffuserLhs.run(it) }

                    assertEquals(outputRhs, outputLhs)
                    outputRhs == outputLhs
                }
    }

    @Test
    fun `map() conforms to identity law`() {
        // identity
        // map({ it }, diffuser) == diffuser
        diffusersBehaveTheSame(
                formula(
                        { diffuser -> map({ it }, diffuser) },
                        { diffuser -> diffuser }
                )
        )
    }

    @Test
    fun `map() applies transformation to all values`() {
        // map(f, diffuser) == intoAlways { diffuser.run(f(it)) }
        diffusersBehaveTheSame(
                transformers.flatMap { f ->
                    formula<Diffuser<Int>>(
                            lhs = { diffuser -> map(f, diffuser) },
                            rhs = { diffuser -> intoAlways { diffuser.run(f.apply(it)) } }
                    )
                }
        )
    }

    @Test
    fun `map() conforms to associativity law`() {
        // associativity
        // map(f, map(g, diffuser)) == map(g . f, diffuser)
        diffusersBehaveTheSame(
                zip(transformers, transformers).flatMap { (f, g) ->
                    formula<Diffuser<Int>>(
                            lhs = { diffuser -> map(f, map(g, diffuser)) },
                            rhs = { diffuser -> map({ g.apply(f.apply(it)) }, diffuser) }
                    )
                }
        )
    }

    @Test
    fun `intoAll() is the same thing as running all children in order`() {
        // Running intoAll() on a list of intoAlways() Diffusers is the same as running a list of
        // into() Diffusers individually.
        qt().forAll(integers().between(0, 10), integerLists)
                .check { d, input ->
                    val outputLhs = mutableListOf<Int>()
                    val diffusersListLhs = (0..d).map { i ->
                        into<Int> { outputLhs.add(i) }
                    }

                    val outputRhs = mutableListOf<Int>()
                    val diffusersListRhs = (0..d).map { i ->
                        intoAlways<Int> { outputRhs.add(i) }
                    }
                    val diffuserRhs = intoAll(diffusersListRhs)

                    input.forEach { value ->
                        diffusersListLhs.forEach { diffuser -> diffuser.run(value) }

                        diffuserRhs.run(value)
                    }

                    Assert.assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }

    @Test
    fun `intoAll with varargs is the same as intoAll with a list`() {
        // intoAll(a) == intoAll(listOf(a))
        diffusersBehaveTheSame(
                formula(
                        lhs = { diffuser -> intoAll(diffuser) },
                        rhs = { diffuser -> intoAll(listOf(diffuser)) }
                )
        )
    }

    @Test
    fun `constructor with varargs is the same as intoAll with a list`() {
        // Diffuser(a) == intoAll(listOf(a))
        diffusersBehaveTheSame(
                formula(
                        lhs = { diffuser -> Diffuser(diffuser) },
                        rhs = { diffuser -> intoAll(listOf(diffuser)) }
                )
        )
    }

    @Test
    fun `constructor with collection is the same as intoAll with a list`() {
        // Diffuser(listOf(a)) == intoAll(listOf(a))
        diffusersBehaveTheSame(
                formula(
                        lhs = { diffuser -> Diffuser(listOf(diffuser)) },
                        rhs = { diffuser -> intoAll(listOf(diffuser)) }
                )
        )
    }
}
