/*
 * Copyright 2024-present Open Networking Foundation
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
package nycu.winlab.groupmeter;

import org.onosproject.core.ApplicationId;
import org.onosproject.net.ConnectPoint;
import org.onosproject.net.config.Config;
import org.onlab.packet.IpAddress;
import org.onlab.packet.MacAddress;

public class NameConfig extends Config<ApplicationId> {

    private static final String HOST_1 = "host-1";
    private static final String HOST_2 = "host-2";
    private static final String MAC_1 = "mac-1";
    private static final String MAC_2 = "mac-2";
    private static final String IP_1 = "ip-1";
    private static final String IP_2 = "ip-2";

    @Override
    public boolean isValid() {
        return hasOnlyFields(HOST_1, HOST_2, MAC_1, MAC_2, IP_1, IP_2);
    }

    public ConnectPoint host1ConnectPoint() {
        return ConnectPoint.deviceConnectPoint(get(HOST_1, null));
    }

    public ConnectPoint host2ConnectPoint() {
        return ConnectPoint.deviceConnectPoint(get(HOST_2, null));
    }

    public MacAddress mac1() {
        return MacAddress.valueOf(get(MAC_1, null));
    }

    public MacAddress mac2() {
        return MacAddress.valueOf(get(MAC_2, null));
    }

    public IpAddress ip1() {
        return IpAddress.valueOf(get(IP_1, null));
    }

    public IpAddress ip2() {
        return IpAddress.valueOf(get(IP_2, null));
    }
}
