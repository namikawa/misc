require 'rubygems'
require 'net/ssh'

### config
SERVER = "192.168.100.100"
SSH_USER = "username"
SSH_USER_KEY = "~/.ssh/id_rsa"

MYSQL_CMD = "/usr/bin/mysql"
MYSQL_USER = "root"
MYSQL_DB = "database_name"

OSC_CMD = "/usr/bin/pt-online-schema-change"
OSC_SET_VARS = "sql_log_bin=0"
OSC_KEY_BLOCK_SIZE = "8"

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

    # innodb_file_formatをBarracudaに変更
    # TODO: コメントアウト外す
    #exec_query("set global innodb_file_format='Barracuda';")
    #exec_query("set global innodb_file_format_max='Barracuda';")

    # innodb_stats_on_metadataのOFF
    metadata_mod = false
    if exec_query("show global variables like 'innodb_stats_on_metadata';").include?("ON")
      exec_query("set global innodb_stats_on_metadata=OFF;")
      metadata_mod = true
    end

    # TODO: dry-runのチェックどうするか
    # TODO: online-schema-changeの実行

    # innodb_stats_on_metadataのON (OFFに変更した場合)
    if metadata_mod
      exec_query("set global innodb_stats_on_metadata=ON;")
    end

  end
end

### execute
AllTableCompresser.run()

