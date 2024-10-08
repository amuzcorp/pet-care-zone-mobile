/*
 * WebAppSessionListener
 * Connect SDK
 *
 * Copyright (c) 2014 LG Electronics.
 * Created by Jeffrey Glenn on 07 Mar 2014
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.connectsdk.service.sessions;

public interface WebAppSessionListener {

    /**
     * This method is called when a message is received from a web app.
     *
     * @param webAppSession WebAppSession that corresponds to the web app that sent the message
     * @param message Object from the web app, either an String or a JSONObject
     */
    public void onReceiveMessage(WebAppSession webAppSession, Object message);

    /**
     * This method is called when a web app's communication channel (WebSocket, etc) has become disconnected.
     *
     * @param webAppSession WebAppSession that became disconnected
     */
    public void onWebAppSessionDisconnect(WebAppSession webAppSession);
}
