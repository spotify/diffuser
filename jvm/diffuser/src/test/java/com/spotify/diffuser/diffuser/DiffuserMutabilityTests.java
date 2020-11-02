package com.spotify.diffuser.diffuser;

import static com.spotify.diffuser.diffuser.Diffuser.into;

import java.util.ArrayList;
import java.util.List;
import org.junit.Assert;
import org.junit.Test;

public class DiffuserMutabilityTests {

  @Test
  public void diffuserCreatedFromArrayIsNotExternallyModifiable() {
    Diffuser<Integer> expectedDiffuser = into(a -> {});
    Diffuser<Integer> incorrectDiffuser = into(a -> Assert.fail("This diffuser should not be run"));

    Diffuser<Integer>[] children = new Diffuser[] {expectedDiffuser};
    Diffuser diffuser = new Diffuser<>(children);
    diffuser.run(1);
    children[0] = incorrectDiffuser;
    diffuser.run(2);
  }

  @Test
  public void diffuserCreatedFromCollectionIsNotExternallyModifiable() {
    Diffuser<Integer> incorrectDiffuser = into(a -> Assert.fail("This diffuser should not be run"));

    List<Diffuser<Integer>> children = new ArrayList<>();
    Diffuser diffuser = new Diffuser<>(children);
    diffuser.run(1);
    children.add(incorrectDiffuser);
  }
}
