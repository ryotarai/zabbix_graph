require "zabbix_graph/version"
require "zabbixapi"
require "peco_selector"

module ZabbixGraph
  class CLI
    def self.start(argv)
      Opener.new.select_and_open
    end
  end

  class Opener
    def select_and_open
      hosts = zbx.hosts.get({})
      hosts = PecoSelector.select_from(hosts.sort_by do |h|
        h['host']
      end.map do |h|
        [h['host'], h]
      end)

      items = zbx.client.api_request(
        method: 'item.get',
        params: {
          hostids: hosts.map {|h| h['hostid'] },
        },
      )

      selected = PecoSelector.select_from(items.map do |i|
        [i['name'], i['key_']]
      end.uniq.map do |name, key|
        ["#{name} (#{key})", [name, key]]
      end)

      selected_items = items.select do |i|
        selected.any? do |name, key|
          i['name'] == name && i['key_'] == key
        end
      end

      query = [['action', 'batchgraph'], ['graphtype', '0']]
      selected_items.each do |i|
        query << ['itemids[]', i['itemid']]
      end

      url = URI.join(zabbix_url, "/history.php?#{URI.encode_www_form(query)}")

      system 'open', url.to_s
    end

    private

    def zbx
      @zbx ||= ZabbixApi.connect(
        url: URI.join(zabbix_url, '/api_jsonrpc.php').to_s,
        user: zabbix_user,
        password: zabbix_password,
      )
    end

    def zabbix_url
      env('ZABBIX_URL')
    end

    def zabbix_user
      env('ZABBIX_USER')
    end

    def zabbix_password
      env('ZABBIX_PASSWORD')
    end

    def env(key)
      ret = ENV[key]

      unless ret
        $stderr.puts "#{key} is not set."
        abort
      end

      ret
    end
  end
end
