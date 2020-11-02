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
import com.spotify.diffuser.GenUtils.alwaysChanged
import com.spotify.diffuser.GenUtils.didChanges
import com.spotify.diffuser.diffuser.Diffuser.into
import com.spotify.diffuser.diffuser.Diffuser.intoAlways
import com.spotify.diffuser.diffuser.Diffuser.intoOnce
import com.spotify.diffuser.diffuser.Diffuser.intoWhen
import org.junit.Test
import org.quicktheories.WithQuickTheories

class DiffuserIntoTest : WithQuickTheories {

    @Test
    fun `intoWhen(alwaysChanged, effect) is the same thing as intoAlways(effect)`() {
        // intoWhen({ true }, eff) == intoAlways(eff)
        effectsBehaveTheSame(
                formula(
                        lhs = { eff -> intoWhen(alwaysChanged, eff) },
                        rhs = { eff -> intoAlways(eff) }
                )
        )
    }

    @Test
    fun `intoWhen(didChange, effect) is the same thing as intoWhen(didChange, intoAlways(effect)`() {
        // intoWhen(didChange, eff) == intoWhen(didChange, intoAlways(eff))
        effectsBehaveTheSame(
                didChanges.flatMap { didChange ->
                    formula<Effect<Int>>(
                            lhs = { eff -> intoWhen(didChange, eff) },
                            rhs = { eff -> intoWhen(didChange, intoAlways(eff)) }
                    )
                }
        )
    }

    @Test
    fun `into(effect) is the same thing as intoWhen(notEqual, intoAlways(effect))`() {
        // into(eff) == intoWhen((!=), intoAlways(eff))
        effectsBehaveTheSame(
                formula(
                        lhs = { eff -> into(eff) },
                        rhs = { eff -> intoWhen({ a, b -> a != b }, intoAlways(eff)) }
                )
        )
    }

    @Test
    fun `intoOnce(effect) is the same thing as intoWhen({ false }, intoAlways(effect))`() {
        // intoOnce(eff) == intoWhen({ false }, intoAlways(eff))
        effectsBehaveTheSame(
                formula(
                        lhs = { eff -> intoOnce(eff) },
                        rhs = { eff -> intoWhen({ _, _ -> false }, intoAlways(eff)) }
                )
        )
    }
}
