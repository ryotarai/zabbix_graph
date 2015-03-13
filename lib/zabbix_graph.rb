require "zabbix_graph/version"
require "zabbixapi"
require "peco_selector"
require "optparse"
require "fileutils"

module ZabbixGraph
  class CLI
    def self.start(argv)
      Opener.new(parse_argv(argv)).select_and_open
    end

    def self.parse_argv(argv)
      options = {}

      parser = OptionParser.new
      parser.on('--host-graph') { options[:host_graph] = true }
      parser.on('--item-graph') { options[:item_graph] = true }
      parser.on('--period=VAL') {|v| options[:period] = v }
      parser.parse!(argv)

      options
    end
  end

  class Opener
    def initialize(options)
      @options = options
      @all_hosts = zbx.hosts.get({})
    end

    def select_and_open
      hosts = PecoSelector.select_from(@all_hosts.sort_by do |h|
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

      if @options[:host_graph]
        open_host_graph(selected_items)
      elsif @options[:item_graph]
        open_item_graph(selected_items)
      else
        open_history(selected_items)
      end
    end

    private

    def open_history(items)
      url = URI.join(zabbix_url, "/history.php?#{query_string_from_items(items)}")

      system 'open', url.to_s
    end

    def open_host_graph(items)
      host_items = items.group_by do |i|
        i['hostid']
      end

      grouped_items = host_items.map do |hostid, items|
        host = @all_hosts.find {|h| h['hostid'] == hostid }
        [host['name'], items]
      end.sort_by do |hostname, _|
        hostname
      end
        
      open_grouped_items(grouped_items)
    end

    def open_item_graph(items)
      key_items = items.group_by do |i|
        [i['name'], i['key_']]
      end

      grouped_items = key_items.sort_by do |name_key, _|
        name_key.join
      end.map do |name_key, items|
        ["#{name_key[0]} (#{name_key[1]})", items]
      end

      open_grouped_items(grouped_items)
    end

    def open_grouped_items(grouped_items)
      html = ""
      grouped_items.each do |name, items|
        src = URI.join(zabbix_url, "/chart.php?#{query_string_from_items(items)}").to_s
        html << "<div>"
        html << "<h2>" << name << "</h2>"
        html << %{<img src="#{src}">}
        html << "</div>"
      end

      path = File.join(temp_html_dir, "#{Time.now.to_f.to_s}.html")
      open(path, 'w') do |f|
        f.write html
      end

      system 'open', path
    end

    def temp_html_dir
      dir = "/tmp/zabbix_graph"
      FileUtils.mkdir_p(dir)

      dir
    end

    def query_string_from_items(items)
      query = [['action', 'batchgraph'], ['graphtype', '0'], ['period', period.to_s]]
      items.each do |i|
        query << ['itemids[]', i['itemid']]
      end

      URI.encode_www_form(query)
    end

    def period
      return 3600 unless @options[:period]

      @options[:period].scan(/(\d+)([smhd])/).map do |part|
        scale = case part[1]
                when "s"
                  1
                when "m"
                  60
                when "h"
                  60 * 60
                when "d"
                  60 * 60 * 24
                end
        part[0].to_i * scale
      end.inject(0) {|sum, i| sum + i }
    end

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
