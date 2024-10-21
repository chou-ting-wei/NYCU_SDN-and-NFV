from mininet.topo import Topo

class Demo_Topo_112550013( Topo ):
    def __init__( self ):
        Topo.__init__( self )

        # Define IP addresses for each host
        ip_addresses = {
            'h1': '192.168.130.1/27',
            'h2': '192.168.130.2/27',
            'h3': '192.168.130.3/27'
        }
        
        mac_addresses = {
            'h1': '00:00:00:00:00:01',
            'h2': '00:00:00:00:00:02',
            'h3': '00:00:00:00:00:03'
        }
        
        # Add hosts with specific IP addresses
        hosts = { name: self.addHost(name, ip=ip_addresses[name], mac=mac_addresses[name],  defaultRoute='via 192.168.130.30') for name in ip_addresses }

        # Add switches
        s1 = self.addSwitch( 's1' )
        
        # Add links
        self.addLink(hosts['h1'], s1)
        self.addLink(hosts['h2'], s1)
        self.addLink(hosts['h3'], s1)


topos = { 'topo_part2_112550013': Demo_Topo_112550013 }