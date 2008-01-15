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
  
  if dom_obj.name["group"] #group要素ならば
    
    if dom_obj.attributes["id"] == eid
      dom_obj.each_element do |elem|
        
        if elem.attributes["id"] != ""
          #問題提示用のID取得
          if elem.name["q"]
            ques_buff += elem.attributes["id"]
            #オブジェクトダウンロード用のID取得
          elsif elem.name["o"]
            obj_buff += elem.attributes["id"]
            #makefileダウンロード用のID取得
          elsif elem.name["m"]
            make_buff += elem.attributes["id"]
            #ヒント提示用のIDを取得
          elsif elem.name["h"] 
            if elem.attributes["level"] == "all" 
              hint_buff += elem.attributes["id"]
            elsif elem.attributes["level"].to_i == level
              hint_buff += "," + elem.attributes["id"]
            end
            #テストダウンロード用のID取得
          elsif elem.name["t"]
            ts_buff = elem.attributes["id"]
          else
          end
        end
      end

      #問題を提示するためのIDを配列に入れる
      ques = ques_buff.split(',')
      print "問題"
      print ques
      #オブジェクトをダウンロードするためのIDを配列に入れる
      if obj_buff.length !=0
        obj = obj_buff.split(',')
        print "オブジェクト"
        print obj
      end
      #makefileをダウンロードするためのIDを配列に入れる
      if make_buff.length != 0
        make = make_buff.split(',')
        print "メークファイル"
        print make
      end
      #ヒントを提示するためのIDを配列に入れる
      hints = hint_buff.split(',')
      print "ヒント"
      print hints
      #テストをダウンロードするためのIDを配列に入れる
      if ts_buff.length != 0
        ts = ts_buff.split(',')
        print "テスト"
        print ts
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

  elsif dom_obj.name["download"] #download要素ならば

  elsif dom_obj.name["question"] #question要素ならば

  elsif dom_obj.name["source"] #source要素ならば

  else
    
  end

  return str_buff
end



#再帰的にノードを検索
def XTDLNodeSearch(dom_obj,eid,level)
  #意味要素配列
  semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation","exercise"]
  
  
  str_buff = ""
  flag = false #判定フラグ
  if dom_obj.name["xtdl"] # xtdl要素ならば
    str_buff += "エックスティディーエル"
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["section"] # section要素ならば
    str_buff += "セクション"
    if dom_obj.attributes["title"] != ""
      str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h2>"
    else
      str_buff += "<br /><br />"
    end
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["exercise"] #exercise要素ならば
    str_buff += "エクササイズ"
    dom_obj.each_element do |elem|
      str_buff += ExerciseRead(elem,eid,level)
    end
  else # 意味要素ならば
    str_buff += "意味要素"
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
      str_buff += "動作確認"
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

#cgi = CGI.new
str_buff = ""

# Form入力値のチェック
src_name = "tchar3.xml"#cgi["src_name"]
dir_name = "/work/"#cgi["dir"]
id = "nil"#cgi["id"]
eid = "teiji001"#cgi["eid"]
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

level = 1
#ファイル読み込み
file_name = "tchar3.xml"
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
