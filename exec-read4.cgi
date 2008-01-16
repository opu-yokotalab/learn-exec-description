#!/usr/bin/ruby

require 'cgi'
require "kconv"
require "rexml/document"
require 'net/http'

#入力された値をチェックする関数
def srcNameCheck(src_name,dir_name,e_id)
  err_code = 0
  if src_name.length == 0
    err_code += 1
  end

  if dir_name.length == 0
    err_code += 2
  end
  if e_id.length == 0
    err_code += 4
  end
  return err_code
end

# 画面を出力する関数
def view(body_str)
  print "Content-type: text/html\n\n"
  print "<html><head><title>X-TDL Viewer</title>"
  print "<link href=\"learning.css\" rel=\"stylesheet\" type=\"text/css\">"

  print "<link href=\"prettify.css\" type=\"text/css\" rel=\"stylesheet\" /> <script type=\"text/javascript\" src=\"prettify.js\"></script>"

  print "<script type=\"text/javascript\">try{	window.addEventListener(\"load\",prettyPrint,false);}catch(e){	window.attachEvent(\"onload\",prettyPrint);}</script>"

  print "</head><body>"
  print body_str
  print "</body></html>"
  return
end

def ExerciseRead(dom_obj,eid,level)
  
  str_buff = ""
  ques_buff = ""
  obj_buff = ""
  make_buff = ""
  hint_buff = ""
  ts_buff = ""
  
  #問題内容を書き込むためにファイルを開く
  out_q = open("question.txt","w")
  #ソースファイル用のコードを書き込むためのファイルを開く
  out_s = open("source.txt","w")

  dom_obj.each_element do |elem|

    if elem.name["group"] #group要素ならば
      
      if elem.attributes["id"] == eid
        elem.each_element do |el|
          
          if el.attributes["id"] != ""
            #問題提示用のID取得
            if el.name["q"]
              ques_buff += el.attributes["id"]
              #オブジェクトダウンロード用のID取得
            elsif el.name["o"]
              obj_buff += el.attributes["id"]
              #makefileダウンロード用のID取得
            elsif el.name["m"]
              make_buff += el.attributes["id"]
              #ヒント提示用のIDを取得
            elsif el.name["h"] 
              if el.attributes["level"] == "all" 
                hint_buff += el.attributes["id"]
              elsif el.attributes["level"].to_i == level
                hint_buff += "," + el.attributes["id"]
              end
              #テストダウンロード用のID取得
            elsif el.name["t"]
              ts_buff = el.attributes["id"]
            end
          end
        end


        #オブジェクトをダウンロードするためのIDを配列に入れる
        if elem.length !=0
          obj = obj_buff.split(',')
          # print "オブジェクト"
          # print obj
        end
        #makefileをダウンロードするためのIDを配列に入れる
        if make_buff.length != 0
          make = make_buff.split(',')
          #print "メークファイル"
          #print make
        end


        #テストをダウンロードするためのIDを配列に入れる
        if ts_buff.length != 0
          ts = ts_buff.split(',')
          #print "テスト"
          #print ts
        end
      end
##各IDの格納リスト名
#
#問題         :ques
#オブジェクト :obj
#makefile     :make
#ヒント       :hints
#テストデータ :ts
###

    elsif elem.name["download"] #download要素ならば
    elsif elem.name["question"] #question要素ならば
      #問題を提示するためのIDを配列に入れる
      ques = ques_buff.split(',')
      for i in ques
        #idが一致する問題の記述内容を探し出す
        if elem.attributes["id"] == i
          out_q.print(elem.text)
          str_buff += elem.text.gsub("\n","<br>")
          #str_buff.gsub('\n',"<br>")
        end
      end
    elsif elem.name["source"] #source要素ならば
      #ヒントを提示するためのIDを配列に入れる
      num = 1
      hints = hint_buff.split(',')
      elem.each_element do |el|
        #子要素がitemなら
        if el.name["item"]
          #fg = false
          for i in hints
            #idが一致したもののテキストを取り出す
            if el.attributes["id"] ==i
                  #画面に表示する場合
                  #str_buff += el.text
                  #str_buff += "\n"
              out_s.print(el.text)
              out_s.print("\n")
              #fg = true
            end
          end
          #if fg != true
          #  str_buff += "[" 
          #  str_buff += num.to_s
          #  str_buff +=  "]\n"
          #  num = num + 1
          #end
          #子要素がcommentなら
        elsif el.name["comment"]
        end
      end
    end
  end
  #書き込み用ファイルのクローズ
  out_q.close
  out_s.close
  return str_buff
end


#再帰的にノードを検索
def XTDLNodeSearch(dom_obj,eid,level)
  #意味要素配列
  semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation","exercise"]
  
  
  str_buff = ""
  flag = false #判定フラグ
  if dom_obj.name["xtdl"] # xtdl要素ならば
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["section"] # section要素ならば
    if dom_obj.attributes["title"] != ""
      str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h2>"
    else
      str_buff += "<br /><br />"
    end
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["exercise"] #exercise要素ならば
    str_buff += "<b>演習問題</b><p>"
    str_buff += ExerciseRead(dom_obj,eid,level)
    str_buff += "</p>"
  else # 意味要素ならば
    if dom_obj.attributes["title"] != ""
      str_buff += "<h3>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h3>"
    else
      str_buff += "<br /><br />"
    end
    #子はHTML?または意味要素?
    semantic_elem_array.each do |semantic_elem|
      if dom_obj.elements["./#{semantic_elem}"]
        flag = true
      end
    end
    
    if flag
      #意味要素の場合
      dom_obj.each_element do |elem|
        str_buff += XTDLNodeSearch(elem,eid,level)
      end
    else
      # HTMLの場合
      dom_obj.each do |elem|
        str_buff += elem.to_s.toutf8
      end
    end
  end
  
  return str_buff
end

cgi = CGI.new
str_buff = ""

# Form入力値のチェック
src_name = cgi["src_name"]
dir_name = "/work/"#cgi["dir"]
id = "1"#cgi["id"]
eid = cgi["eid"]
level = cgi["lebel"]
err_code = srcNameCheck(src_name,dir_name,eid)

#入力値のチェック
if err_code > 0 then
  body_str = "<h3>Application Error!!</h3>"
  case err_code
  when 1 then
    body_str += "<p>リソース名を入力してください<p>"
  when 2 then
    body_str += "<p>作業フォルダ名を入力してください</p>"
  when 3 then
    body_str += "<p>作業フォルダ名、およびリソース名を入力してください</p>"
  when 4 then
    body_str += "<p>演習idを入力してください<p>"
  when 5 then
    body_str += "<p>リソース名と演習idを入力してください</p>"
  when 6 then
    body_str += "<p>作業フォルダ名と演習idを入力してください</p>"
  when 7 then
    body_str += "<p>リソース名と作業フォルダ名、演習idを入力してください<p>"
  end
  view(body_str.toutf8)
  return
end

#ファイル読み込み
file_name = src_name
doc = nil
file = File.new(file_name)
doc = REXML::Document.new file
if doc
  body_str = XTDLNodeSearch(doc.root,eid,level)
else
  body_str = "<h3>Error!!,/h3>"
end

#結果出力
view(body_str.toutf8)
