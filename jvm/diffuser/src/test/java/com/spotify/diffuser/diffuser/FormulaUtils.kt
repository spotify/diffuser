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

import com.spotify.diffuser.Effect
import com.spotify.diffuser.GenUtils.integerLists
import com.spotify.diffuser.diffuser.Diffuser.intoAlways
import org.junit.Assert.assertEquals
import org.quicktheories.QuickTheory.qt
import org.quicktheories.core.Gen
import org.quicktheories.generators.Generate.constant


fun effectsBehaveTheSame(formulas: Gen<Formula<Effect<Int>>>) {
    behaveTheSame({ it }, formulas)
}

fun diffusersBehaveTheSame(formulas: Gen<Formula<Diffuser<Int>>>) {
    behaveTheSame({ intoAlways(it) }, formulas)
}

data class Formula<I>(
        val lhs: (I) -> Diffuser<Int>,
        val rhs: (I) -> Diffuser<Int>)

fun <I> formula(lhs: (I) -> Diffuser<Int>, rhs: (I) -> Diffuser<Int>) = constant(Formula(lhs, rhs))

private fun <I> behaveTheSame(
        effectAdapter: (Effect<Int>) -> I,
        formulas: Gen<Formula<I>>) {

    qt().forAll(integerLists, formulas)
            .check { input, formula ->
                val outputLhs = mutableListOf<Int>()
                val outputRhs = mutableListOf<Int>()

                val diffuserLhs = formula.lhs(effectAdapter(Effect { outputLhs.add(it) }))
                val diffuserRhs = formula.rhs(effectAdapter(Effect { outputRhs.add(it) }))

                input.forEach {
                    diffuserLhs.run(it)
                    diffuserRhs.run(it)
                }

                assertEquals(outputRhs, outputLhs)
                outputLhs == outputRhs
            }
}
