/*
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
/*
 * This code was generated by https://github.com/google/apis-client-generator/
 * (build: 2016-01-08 17:48:37 UTC)
 * on 2016-01-18 at 19:07:33 UTC 
 * Modify at your own risk.
 */

package com.myverbatm.verbatm.verbatmbackend.com.myverbatm.verbatm.backend.apis.verbatmApp.model;

/**
 * Model definition for Page.
 *
 * <p> This is the Java data model class that specifies how to parse/serialize into the JSON that is
 * transmitted over HTTP when working with the verbatmApp. For a detailed explanation see:
 * <a href="https://developers.google.com/api-client-library/java/google-http-java-client/json">https://developers.google.com/api-client-library/java/google-http-java-client/json</a>
 * </p>
 *
 * @author Google, Inc.
 */
@SuppressWarnings("javadoc")
public final class Page extends com.google.api.client.json.GenericJson {

  /**
   * The value may be {@code null}.
   */
  @com.google.api.client.util.Key
  private java.lang.Integer id;

  /**
   * The value may be {@code null}.
   */
  @com.google.api.client.util.Key
  private java.lang.Integer pageNumberInPost;

  /**
   * @return value or {@code null} for none
   */
  public java.lang.Integer getId() {
    return id;
  }

  /**
   * @param id id or {@code null} for none
   */
  public Page setId(java.lang.Integer id) {
    this.id = id;
    return this;
  }

  /**
   * @return value or {@code null} for none
   */
  public java.lang.Integer getPageNumberInPost() {
    return pageNumberInPost;
  }

  /**
   * @param pageNumberInPost pageNumberInPost or {@code null} for none
   */
  public Page setPageNumberInPost(java.lang.Integer pageNumberInPost) {
    this.pageNumberInPost = pageNumberInPost;
    return this;
  }

  @Override
  public Page set(String fieldName, Object value) {
    return (Page) super.set(fieldName, value);
  }

  @Override
  public Page clone() {
    return (Page) super.clone();
  }

}
