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
  print "<html><head> <meta content=\"text/html; charset=utf-8\" http-equiv=\"content-type\"> <title>演習提示スクリプト</title>"
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
  com_buff = ""
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
              ques_buff += el.attributes["idrefs"]
            elsif el.name["d"]
              #オブジェクトダウンロード用のID取得
              obj_buff += el.attributes["idref"]
              #テストダウンロード用のID取得
              ts_buff += el.attributes["tidref"]
              #ヒント提示用のIDを取得
            elsif el.name["h"] 
              if el.attributes["level"] == "all" 
                hint_buff += el.attributes["idrefs"]
                com_buff += el.attributes["cidrefs"]
              elsif el.attributes["level"].to_i == level
                hint_buff += ","
                hint_buff += el.attributes["idrefs"]
                com_buff += ","
                com_buff += el.attributes["cidrefs"]
              end
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
        #if make_buff.length != 0
        #  make = make_buff.split(',')
          #print "メークファイル"
          #print make
        #end

        
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
      
    elsif elem.name["resource"] #教材リソースならば
      elem.each_element do |ment|
        if ment.name["download"] #download要素ならば
          
        elsif ment.name["question"] #question要素ならば
          #問題を提示するためのIDを配列に入れる
          ques = ques_buff.split(',')
          ment.each_element do |el|
            for i in ques
              #idが一致する問題の記述内容を探し出す
              if el.attributes["id"] == i
                out_q.print(el.text)
                str_buff += el.text#.gsub("\n","<br>\n")
              end
            end
          end
        elsif ment.name["source"] #source要素ならば
          str_buff += "<br><b>ソースコード</b><br>"
          #ヒントを提示するためのIDを配列に入れる
          num = 1
          hints = hint_buff.split(',')
          com = com_buff.split(',')
          
          ment.each_element do |el|
            #子要素がitemなら
            if el.name["item"]
              #fg = false
              for i in hints
                #idが一致したもののテキストを取り出す
                if el.attributes["id"] == i
                  #画面に表示する場合
                  str_buff += "<font color=\"blue\">"
                  str_buff += el.text
                  str_buff += "\n"
                  str_buff += "</font>"
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
              for j in com
                if el.attributes["id"] == j
                  out_s.print(el.text)
                  out_s.print("\n")
                  str_buff += "<font color=\"green\">"
                  str_buff += el.text
                  str_buff += "\n"
                  str_buff += "</font>"
                end
              end
            end
          end
        end
      end
    end
  end
  #書き込み用ファイルのクローズ
  out_q.close
  out_s.close
  return str_buff.gsub("\n","<br>\n")
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
dir_name = cgi["dir"]
id = cgi["id"]
eid = cgi["eid"]
level = cgi["level"]
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
file_name = "#{src_name}.xml"
doc = nil
file = File.new(file_name)
doc = REXML::Document.new file
if doc
  body_str = XTDLNodeSearch(doc.root,eid,level.to_i)
else
  body_str = "<h3>Error!!,/h3>"
end

#結果出力
view(body_str.toutf8)
