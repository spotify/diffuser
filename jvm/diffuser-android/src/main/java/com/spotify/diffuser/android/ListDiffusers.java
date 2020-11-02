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

import static com.spotify.diffuser.diffuser.Diffuser.intoAlways;

import androidx.recyclerview.widget.ListAdapter;
import androidx.recyclerview.widget.RecyclerView;
import com.spotify.diffuser.diffuser.Diffuser;
import java.util.List;

public class ListDiffusers {

  /**
   * Create a Diffuser<T> which will feed a List<T> into a ListAdapter.
   *
   * @param listAdapter - The list adapter that should be updated when the Diffuser receives input.
   * @param <T> The type of items in the list
   * @param <VH> The type of the ListAdapter's ViewHolder
   * @return A Diffuser which supplies a ListAdapter with data.
   */
  public static <T, VH extends RecyclerView.ViewHolder> Diffuser<List<T>> intoListAdapter(
      ListAdapter<T, VH> listAdapter) {
    return intoAlways(listAdapter::submitList);
  }
}
