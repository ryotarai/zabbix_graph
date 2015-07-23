# ZabbixGraph [![Gem Version](https://badge.fury.io/rb/zabbix_graph.svg)](http://badge.fury.io/rb/zabbix_graph)

Select hosts and items with peco, and open adhoc graph.

## Installation

    $ gem install zabbix_graph

## Usage

```
$ export ZABBIX_URL=https://your-zabbix.example.com
$ export ZABBIX_USER=...
$ export ZABBIX_PASSWORD=...
$ zabbix_graph
```

### --item-graph and --host-graph

You can view graphs per item or host.

```
$ zabbix_graph --item-graph
$ zabbix_graph --host-graph
$ zabbix_graph --item-graph --period=1d1h1m1s
$ zabbix_graph --host-graph --period=1d1h1m1s
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/zabbix_graph/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
