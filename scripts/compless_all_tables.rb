require 'rubygems'
require 'net/ssh'

### config
SERVER = "192.168.100.100"
SSH_USER = "username"
SSH_USER_KEY = "~/.ssh/id_rsa"

MYSQL_CMD = "/usr/bin/mysql"
MYSQL_USER = "root"
MYSQL_DB = "database_name"

OSC_CMD = ""

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
  def self.exec_online_schema_change()
  end

  # 特定のDBの全テーブルを取得してそのリストをサイズ順にして返す
  def self.get_sorted_tables(db)
    result = exec_query("select table_name from information_schema.tables where table_schema = '#{db}' order by data_length asc;")
    list = result.rstrip.split(/\r?\n/).map {|line| line.chomp}
    list.delete("table_name")
    return list
  end

  # テーブルのリストから圧縮対象となるリストを返す
  def self.get_target_tables_by_list(db, table_list)
    target_list = []
    table_list.each do |table|
      desc = exec_query("show create table #{db}.#{table};")
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
  def self.run(db)
    target_tables =  get_target_tables_by_list(db, get_sorted_tables(db))

    # TODO: innodb_file_formatの確認
    # TODO: innodb_stats_on_metadataのOFF
    # TODO: dry-runのチェックどうするか
    # TODO: online-schema-changeの実行
    # TODO: innodb_stats_on_metadataのON
  end
end

### execute
AllTableCompresser.run(MYSQL_DB)

