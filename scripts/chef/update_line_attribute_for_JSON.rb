require 'rubygems'
require 'net/ssh'
require 'json'
require 'orderedhash'

### config
NODE_FILES = "./../nodes/*.json"
BTFLY_HOST = "127.0.0.1"
BTFLY_USER = "admin"
BTFLY_USER_KEY = "~/.ssh/id_rsa"
BTFLY_CMD = "/usr/local/bin/run_btfly.sh"
DOMAIN_NAME = ".example.com"

### gen
btfly_info = {"host" => BTFLY_HOST, "user" => BTFLY_USER, "user_key" => {:keys => BTFLY_USER_KEY}}

### class
# サーバの系統情報を保持するクラス
class GroupInfo
  def initialize(listA, listB)
    @groupA_list = listA
    @groupB_list = listB
  end

  # node名をもとに、そのサーバが所属している系統を返す
  def get_line(hostname)
    if @groupA_list.include?(hostname) then
      return "A"
    elsif @groupB_list.include?(hostname) then
      return "B"
    else
      return "none"
    end
  end
end

# JSONファイルのattributeを更新するクラス
class LineAttributeUpdater
  # JSON文字列をOrderdHashで返す
  def self.json_to_hash(json_str)
    return json_str != '' ? JSON.parse(json_str, {:create_additions => false, :object_class => OrderedHash}) : {}
  end

  # JSONに含まれるnode名を返す
  def self.get_node_name(json_str)
    hash = json_to_hash(json_str)
    return hash['name']
  end

  # サーバの系統情報一覧をbtflyに問い合わせて取得する
  def self.get_server_group_list(btfly_info, line)
    result = ""
    Net::SSH.start(btfly_info['host'], btfly_info['user'], btfly_info['user_key']) do |ssh|
      result = ssh.exec!("#{BTFLY_CMD} -t group#{line} out").gsub(DOMAIN_NAME, "").split(" ")
    end
    return result
  end

  # JSONに系統情報を付加した後、整形済みJSONを返す
  def self.add_line_attr_for_json(json_str, line)
    hash = json_to_hash(json_str)
    hash.store("normal", {"user_attr" => {"line" => line }})
    return JSON.pretty_generate(hash)
  end

  # 更新処理
  def self.update(btfly_info)
    # サーバの系統情報一覧の取得
    group_info = GroupInfo.new(get_server_group_list(btfly_info, "A"), get_server_group_list(btfly_info, "B"))

    error = ""
    # ディレクトリ内の該当ファイル数分繰り返し処理
    Dir::glob(NODE_FILES).each do |file_name|
      json = File.read(file_name)
      line = group_info.get_line(get_node_name(json))
      new_json = add_line_attr_for_json(json, line)

      begin
        # JSONへの書き出し処理(上書き)
        open(file_name, "w") {|f| f.write new_json}
      rescue => ex
        STDERR.puts ex.message
      else
        # chef-serverへの登録
        #`knife node from file #{file_name}`
      ensure
        if ex
          STDERR.puts "[ERROR] #{file_name} is not updated."
          error << file_name + "\n"
        else
          STDOUT.puts "[INFO] #{file_name} is updated."
        end
      end
    end

    # 結果のサマリを出力
    if error != "" then
      STDERR.puts "\n[ERROR] Error node lists :"
      STDERR.puts error
      exit!(1)
    else
      STDOUT.puts "\n[INFO] All OK!."
    end
  end
end

### execute
LineAttributeUpdater.update(btfly_info)

