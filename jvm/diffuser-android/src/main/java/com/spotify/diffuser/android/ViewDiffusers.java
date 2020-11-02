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

package com.spotify.diffuser.android;

import static android.view.View.GONE;
import static android.view.View.INVISIBLE;
import static android.view.View.VISIBLE;
import static com.spotify.diffuser.diffuser.Diffuser.into;
import static com.spotify.diffuser.diffuser.Diffuser.map;

import android.view.View;
import android.widget.TextView;
import androidx.annotation.IntDef;
import com.spotify.diffuser.diffuser.Diffuser;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

public class ViewDiffusers {

  /**
   * Create a Diffuser which enables user-interaction on a {@link View} when its input is true, and
   * disables user-interaction when its input is false.
   *
   * @param view - The view managed by this Diffuser.
   * @return A Diffuser which toggles the enabled state of a view based on its input.
   */
  public static Diffuser<Boolean> intoEnabled(View view) {
    return into(view::setEnabled);
  }

  /**
   * Create a Diffuser which disables user-interaction on a {@link View} when its input is true, and
   * enables user-interaction when its input is false.
   *
   * @param view - The view managed by this Diffuser.
   * @return A Diffuser which toggles the disabled state of a view based on its input.
   */
  public static Diffuser<Boolean> intoDisabled(View view) {
    return map(b -> !b, intoEnabled(view));
  }

  @IntDef({VISIBLE, INVISIBLE, GONE})
  @Retention(RetentionPolicy.SOURCE)
  private @interface Visibility {}

  /**
   * Create a Diffuser which toggles a View's visibility based on its input. It will use the {@code
   * enabledVisibility} when true, and the {@code disabledVisibility} when false.
   *
   * @param enabledVisibility - The visibility to use when the Diffuser's input is true.
   * @param disabledVisibility - The visibility to use when the Diffuser's input is false.
   * @param view - The View which is managed by this Diffuser
   * @return A Diffuser which toggles a View's visibility based on its input.
   */
  public static Diffuser<Boolean> intoVisibility(
      @Visibility int enabledVisibility, @Visibility int disabledVisibility, View view) {
    return map(b -> b ? enabledVisibility : disabledVisibility, into(view::setVisibility));
  }

  /**
   * Create a Diffuser which will make a View visible when its input is true, and invisible when
   * false.
   *
   * @param view - The {@link View} managed by this Diffuser.
   * @return A Diffuser which toggles its View's visibility.
   */
  public static Diffuser<Boolean> intoVisibleOrInvisible(View view) {
    return intoVisibility(VISIBLE, INVISIBLE, view);
  }

  /**
   * Create a Diffuser which will make a View visible when its input is true, and set its visibility
   * to gone when false.
   *
   * @param view - The {@link View} managed by this Diffuser.
   * @return A Diffuser which toggles its View's visibility.
   */
  public static Diffuser<Boolean> intoVisibleOrGone(View view) {
    return intoVisibility(VISIBLE, GONE, view);
  }

  /**
   * Create a Diffuser which updates the text of its {@link TextView} based on its input.
   *
   * @param textView - the {@link TextView} managed by this Diffuser.
   * @return A Diffuser which sets the text of a {@link TextView}.
   */
  public static Diffuser<? super CharSequence> intoText(TextView textView) {
    return into(textView::setText);
  }

  /**
   * Create a Diffuser which updates the text of its {@link TextView} based on its input. The text
   * is read from the supplied text resource identifier.
   *
   * @param textView - the {@link TextView} managed by this Diffuser.
   * @return A Diffuser which sets the text of a {@link TextView}.
   */
  public static Diffuser<Integer> intoTextRes(TextView textView) {
    return into(textView::setText);
  }
}
