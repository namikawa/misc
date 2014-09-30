require 'rubygems'
require 'net/ssh'
require 'yaml'

### config
config = YAML.load_file("innodb_compress_all_tables.yml")

SERVER = config["server"]
SSH_USER = config["ssh"]["user"]
SSH_USER_KEY = config["ssh"]["user_key"]
MYSQL_CMD = config["mysql"]["cmd"]
MYSQL_USER = config["mysql"]["user"]
MYSQL_DB = config["mysql"]["db"]
OSC_CMD = config["osc"]["cmd"]
OSC_SET_VARS = config["osc"]["set_vars"]
OSC_KEY_BLOCK_SIZE = config["osc"]["key_block_size"]

### class
class AllTableCompresser
  # SSHコマンドを実行する
  def self.exec_ssh_cmd(cmd)
    result = ""
    Net::SSH.start(SERVER, SSH_USER, {:keys => SSH_USER_KEY}) do |ssh|
      result = ssh.exec!(cmd)
    end
    return result
  end

  # DBクエリを実行する
  def self.exec_query(query)
    return exec_ssh_cmd(%!#{MYSQL_CMD} -u #{MYSQL_USER} -e "#{query}"!)
  end

  # pt-online-schema-changeの実行
  def self.exec_online_schema_change(mode, table)
    return exec_ssh_cmd(%!time #{OSC_CMD} --#{mode} --set-vars="#{OSC_SET_VARS}" --alter "ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=#{OSC_KEY_BLOCK_SIZE}" h=localhost,D=#{MYSQL_DB},t=#{table},u=#{MYSQL_USER}!)
  end

  # 特定のDBの全テーブルを取得してそのリストをサイズ順にして返す
  def self.get_sorted_tables()
    result = exec_query("select table_name from information_schema.tables where table_schema = '#{MYSQL_DB}' order by data_length asc;")
    list = result.rstrip.split(/\r?\n/).map {|line| line.chomp}
    list.delete("table_name")
    return list
  end

  # テーブルのリストから圧縮対象となるリストを返す
  def self.get_target_tables_by_list(table_list)
    target_list = []
    table_list.each do |table|
      desc = exec_query("show create table #{MYSQL_DB}.#{table};")
      if desc.include?("ENGINE=InnoDB") && !desc.include?("ROW_FORMAT=COMPRESSED")
        target_list.push(table)
      end

      if (table =~ /\A_/) && (table =~ /_new\Z/)
        table.slice!(/\A_/)
        table.slice!(/_new\Z/)
        table_list.delete(table)
      end
    end
    return target_list
  end

  # 特定のDBの全テーブルの圧縮を実行する
  def self.run()
    # 圧縮対象となるテーブル一覧の取得
    # TODO: コメントアウト外す
    #target_tables =  get_target_tables_by_list(get_sorted_tables())
    p  get_target_tables_by_list(get_sorted_tables())

    # innodb_file_formatをBarracudaに変更
    # TODO: コメントアウト外す
    #exec_query("set global innodb_file_format='Barracuda';")
    #exec_query("set global innodb_file_format_max='Barracuda';")

    # innodb_stats_on_metadataのOFF
    # TODO: コメントアウト外す
    #metadata_mod = false
    #if exec_query("show global variables like 'innodb_stats_on_metadata';").include?("ON")
    #  exec_query("set global innodb_stats_on_metadata=OFF;")
    #  metadata_mod = true
    #end

    # TODO: dry-runのチェックどうするか
    # TODO: online-schema-changeの実行

    # innodb_stats_on_metadataのON (OFFに変更した場合)
    # TODO: コメントアウト外す
    #if metadata_mod
    #  exec_query("set global innodb_stats_on_metadata=ON;")
    #end

  end
end

### execute
AllTableCompresser.run()

