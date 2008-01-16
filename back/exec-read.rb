#!/usr/bin/ruby

require 'cgi'
require 'kconv'
require 'rexml/document'
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

  if dom_obj.name["group"] ##group要素ならば
    
    if dom_obj.attributes["id"] == eid
      dom_obj.each_element do |elem|
      str_buff += GroupGet(elem,level)
      end
    end

  elsif dom_obj.name["question"] #question要素ならば

  #elsif dom_obj.name["object"] #object要素ならば

  #elsif dom_obj.name["make"] #makefile要素ならば

  #elsif dom_obj.name["test"] #test要素ならば

  elsif dom_obj.name["source"] #source要素ならば

  else
    
  end

  return str_buff
end

def GroupGet(dom_obj,level)
  str_buff = ""
  if dom_obj.name["q"]

  elsif dom_obj.name["o"]
  elsif dom_obj.name["m"]
  elsif dom_obj.name["h"] 
    if dom_obj.attributes["level"] == "all"
      str_buff += dom_obj.text
    elsif dom_obj.attritutes["level"] == level
      str_buff += dom_obj.text
    else
    end
  elsif dom_obj.name["t"]
  else
  end
end

#再帰的にノードを検索
def XTDLNodeSearch(dom_obj,eid,level)
  #意味要素配列
  semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation"]
  
  
  str_buff = ""
  flag = false #判定フラグ
  if dom_obj.name["xtdl"] ## xtdl要素ならば
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["section"] ## section要素ならば
    if dom_obj.attributes["title"] != ""
      str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h2>"
    else
      str_buff += "<br /><br />"
    end
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["exercise"] ##exercise要素ならば
    dom_obj.each_element do |elem|
      str_buff += ExerciseRead(elem,eid,level)
    end
  else ## 意味要素ならば
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
        str += XTDLNodeSearch(elem,eid,level)
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
  body_str = XTDLNodeSearch(doc,eid,level)
else
  body_str = "<h3>Error!!,/h3>"
end

#結果出力
view(body_str.toutf8)
