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

import static com.spotify.diffuser.fuser.Fuser.from;

import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.TextView;
import com.spotify.diffuser.fuser.Fuser;

public class ViewFusers {

  /**
   * Create a Fuser which receives click events from a {@link View}. NOTE: only one click listener
   * can be connected to a view at a time. Connecting multiple Fusers at the same time will result
   * in a crash.
   *
   * @param view - the {@link View} that will emit click events.
   * @return A Fuser which emits click events on its {@link View}.
   */
  public static Fuser<View> fromClicks(View view) {
    return from(
        effect -> {
          if (view.hasOnClickListeners()) {
            throw new IllegalStateException("this View already has a click listener");
          }

          view.setOnClickListener(effect::run);

          return () -> view.setOnClickListener(null);
        });
  }

  /**
   * Create a Fuser which receives long-click events from a {@link View}. NOTE: only one click
   * listener can be added to a view at a time. Connecting multiple Fusers at the same time will
   * result in a crash.
   *
   * @param view - the {@link View} that will emit long-click events.
   * @return A Fuser which emits click events on its {@link View}.
   */
  public static Fuser<Void> fromLongClicks(View view) {
    return from(
        effect -> {
          if (view.hasOnClickListeners()) {
            throw new IllegalStateException("this View already has a longclick listener");
          }

          view.setOnClickListener(v -> effect.run(null));

          return () -> view.setOnLongClickListener(null);
        });
  }

  /**
   * Create a Fuser which receives text changes from a {@link TextView}.
   *
   * @param textView - the {@link TextView} that will emit its text changes.
   * @return A Fuser which emits click events on its {@link TextView}.
   */
  public static Fuser<CharSequence> fromTextChanges(TextView textView) {
    return from(
        effect -> {
          TextWatcher listener =
              new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                  effect.run(s);
                }

                @Override
                public void afterTextChanged(Editable s) {}
              };

          textView.addTextChangedListener(listener);

          return () -> textView.removeTextChangedListener(listener);
        });
  }
}
