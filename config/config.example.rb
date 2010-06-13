
RRDFaces::rrd_base_folder= '/somewhere'

# define some graphs
def net(ifname = 'en0')
  RRDFaces::define_graph("net-#{ifname}", "Interface #{ifname}", RRDFaces::KB_SPEED) do |g|
    g.draw_line("interface/if_octets-#{ifname}.rrd", 'rx', :label => 'Received', :color => 'green', :lineWidth => 4)
    g.draw_line("interface/if_octets-#{ifname}.rrd", 'tx', :label => 'Sent', :color => 'red')
  end
end

memory = RRDFaces::define_graph(:memory, "Memory", RRDFaces::KB_VALUE) do |g|
  g.draw_line('memory/memory-active.rrd', 'value', :label => 'Active', :color => 'green', :lineWidth => 4)
end

def disk(name)
  RRDFaces::define_graph("disk-#{name}", "Disk activity", RRDFaces::DISK_ACCESS) do |g|
    g.draw_line("disk-#{name}/disk_octets.rrd", 'read', :label => 'Read')
    g.draw_line("disk-#{name}/disk_octets.rrd", 'write', :label => 'Write')
  end
end


RRDFaces::define_views do |v|
  # common to all hosts
  v.set_default(memory)
  # host specific (mac is the hostname here)
  v.add_machine(:mac, net('en0'), disk('14-0'))
end



