package com.spotify.diffuser.fuser

import com.spotify.diffuser.GenUtils
import com.spotify.diffuser.fuser.Fuser.from
import com.spotify.diffuser.fuser.Fuser.fromAll
import org.junit.Assert
import org.junit.Test
import org.quicktheories.WithQuickTheories

class FuserConstructorTests: WithQuickTheories {
    @Test
    fun `fromAll with varargs is the same as constructor`() {
        qt().forAll(GenUtils.integerLists)
                .check { input ->
                    val source = TestSource()

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    val fuserLhs = fromAll(from(source))
                    val fuserRhs = Fuser(from(source))

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
    fun `fromAll() is the same as constructor`() {
        qt().forAll(GenUtils.integerLists)
                .check { input ->
                    val source = TestSource()
                    val sources = listOf(from(source))

                    val outputLhs = mutableListOf<Int>()
                    val outputRhs = mutableListOf<Int>()

                    val fuserLhs = fromAll(sources)
                    val fuserRhs = Fuser(sources)

                    val disposableLhs = fuserLhs.connect { outputLhs.add(it) }
                    val disposableRhs = fuserRhs.connect { outputRhs.add(it) }
                    input.forEach { source.emit(it) }
                    disposableLhs.dispose()
                    disposableRhs.dispose()

                    Assert.assertEquals(outputRhs, outputLhs)
                    outputLhs == outputRhs
                }
    }
}
