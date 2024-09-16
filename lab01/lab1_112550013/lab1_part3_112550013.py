from mininet.topo import Topo

class Lab1_Topo_112550013( Topo ):
    def __init__( self ):
        Topo.__init__( self )

        # Define IP addresses for each host
        ip_addresses = {
            'h1': '192.168.0.1/27',
            'h2': '192.168.0.2/27',
            'h3': '192.168.0.3/27',
            'h4': '192.168.0.4/27',
            'h5': '192.168.0.5/27'
        }
        
        # Add hosts with specific IP addresses
        hosts = { name: self.addHost(name, ip=ip_addresses[name], defaultRoute='via 192.168.0.30') for name in ip_addresses }

        # Add switches
        s1 = self.addSwitch( 's1' )
        s2 = self.addSwitch( 's2' )
        s3 = self.addSwitch( 's3' )
        s4 = self.addSwitch( 's4' )
        
        # Add links
        self.addLink(hosts['h1'], s1)
        self.addLink(hosts['h2'], s2)
        self.addLink(hosts['h3'], s3)
        self.addLink(hosts['h4'], s4)
        self.addLink(hosts['h5'], s4)
        
        self.addLink( s1, s2 )
        self.addLink( s2, s3 )
        self.addLink( s2, s4 )


topos = { 'topo_part3_112550013': Lab1_Topo_112550013 }