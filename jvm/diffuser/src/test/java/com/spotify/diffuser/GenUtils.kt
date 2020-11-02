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

package com.spotify.diffuser

import com.spotify.diffuser.diffuser.DidChange
import org.quicktheories.core.Gen
import org.quicktheories.generators.Generate.pick
import org.quicktheories.generators.Generate.range
import org.quicktheories.generators.SourceDSL.lists
import java.util.function.BiFunction

object GenUtils {
    fun <A, B> zip(a: Gen<A>, b: Gen<B>) = a.zip(b, BiFunction<A, B, Pair<A, B>> { p0, p1 ->
        Pair(p0, p1)
    })

    val alwaysChanged: DidChange<Int> = DidChange { _, _ -> true }

    val integerLists = lists()
            .of(range(0, 3))
            .ofSizeBetween(0, 10)

    val didChanges: Gen<DidChange<Int>> = pick(listOf(
            DidChange { a, b -> a != b },
            DidChange { a, b -> a < b },
            DidChange { a, b -> a >= b },
            DidChange { a, b -> a == b }
    ))

    val transformers: Gen<Function<Int,Int>> = pick(listOf(
            Function { it + 1 },
            Function { it - 50 },
            Function { it * 2 },
            Function { -it }
    ))
}
