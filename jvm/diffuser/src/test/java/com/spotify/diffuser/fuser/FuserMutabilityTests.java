package com.spotify.diffuser.fuser;

import static com.spotify.diffuser.fuser.Fuser.from;
import static com.spotify.diffuser.fuser.Fuser.fromAll;

import java.util.ArrayList;
import java.util.List;
import org.junit.Assert;
import org.junit.Test;

public class FuserMutabilityTests {

  @Test
  public void fuserCreatedFromArrayIsNotExternallyMutable() {
    Fuser<Integer> unexpectedFuser =
        from(
            d -> {
              Assert.fail("This fuser should not have been connected");
              return () -> {};
            });
    Fuser<Integer> child = from(d -> () -> {});

    Fuser<Integer>[] children = new Fuser[] {child};

    Fuser<Integer> parent = new Fuser(children);
    children[0] = unexpectedFuser;
    parent.connect(i -> {});
  }

  @Test
  public void fuserCreatedFromListIsNotExternallyMutable() {
    Fuser<Integer> unexpectedFuser =
        from(
            d -> {
              Assert.fail("This fuser should not have been connected");
              return () -> {};
            });

    List<Fuser<Integer>> children = new ArrayList<>();

    Fuser<Integer> parent = fromAll(children);
    children.add(unexpectedFuser);
    parent.connect(i -> {});
  }
}
