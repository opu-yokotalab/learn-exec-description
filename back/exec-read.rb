#!/usr/bin/ruby

require 'cgi'
require 'kconv'
require 'rexml/document'
require 'net/http'

#���Ϥ��줿�ͤ�����å�����ؿ�
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

# ���̤���Ϥ���ؿ�
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

  if dom_obj.name["group"] ##group���Ǥʤ��
    
    if dom_obj.attributes["id"] == eid
      dom_obj.each_element do |elem|
      str_buff += GroupGet(elem,level)
      end
    end

  elsif dom_obj.name["question"] #question���Ǥʤ��

  #elsif dom_obj.name["object"] #object���Ǥʤ��

  #elsif dom_obj.name["make"] #makefile���Ǥʤ��

  #elsif dom_obj.name["test"] #test���Ǥʤ��

  elsif dom_obj.name["source"] #source���Ǥʤ��

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

#�Ƶ�Ū�˥Ρ��ɤ򸡺�
def XTDLNodeSearch(dom_obj,eid,level)
  #��̣��������
  semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation"]
  
  
  str_buff = ""
  flag = false #Ƚ��ե饰
  if dom_obj.name["xtdl"] ## xtdl���Ǥʤ��
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["section"] ## section���Ǥʤ��
    if dom_obj.attributes["title"] != ""
      str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h2>"
    else
      str_buff += "<br /><br />"
    end
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["exercise"] ##exercise���Ǥʤ��
    dom_obj.each_element do |elem|
      str_buff += ExerciseRead(elem,eid,level)
    end
  else ## ��̣���Ǥʤ��
    if dom_obj.attributes["title"] != ""
      str_buff += "<h3>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h3>"
    else
      str_buff += "<br /><br />"
    end
    #�Ҥ�HTML?�ޤ��ϰ�̣����?
    semantic_elem_array.each do |semantic_elem|
      if dom_obj.elements["./#{semantic_elem}"]
        flag = true
      end
    end
    
    if flag
      #��̣���Ǥξ��
      dom_obj.each_element do |elem|
        str += XTDLNodeSearch(elem,eid,level)
      end
    else
      # HTML�ξ��
      dom_obj.each do |elem|
        str_buff += elem.to_s.toutf8
      end
    end
  end
  
  return str_buff
end

#cgi = CGI.new
str_buff = ""

# Form�����ͤΥ����å�
src_name = "tchar3.xml"#cgi["src_name"]
dir_name = "/work/"#cgi["dir"]
id = "nil"#cgi["id"]
eid = "teiji001"#cgi["eid"]
err_code = srcNameCheck(src_name,dir_name,eid)

#�����ͤΥ����å�
if err_code > 0 then
  body_str = "<h3>Application Error!!</h3>"
  case err_code
  when 1 then
    body_str += "<p>�꥽����̾�����Ϥ��Ƥ�������<p>"
  when 2 then
    body_str += "<p>��ȥե����̾�����Ϥ��Ƥ�������</p>"
  when 3 then
    body_str += "<p>��ȥե����̾������ӥ꥽����̾�����Ϥ��Ƥ�������</p>"
  when 4 then
    body_str += "<p>�齬id�����Ϥ��Ƥ�������<p>"
  when 5 then
    body_str += "<p>�꥽����̾�ȱ齬id�����Ϥ��Ƥ�������</p>"
  when 6 then
    body_str += "<p>��ȥե����̾�ȱ齬id�����Ϥ��Ƥ�������</p>"
  when 7 then
    body_str += "<p>�꥽����̾�Ⱥ�ȥե����̾���齬id�����Ϥ��Ƥ�������<p>"
  end
  view(body_str.toutf8)
  return
end

level = 1
#�ե������ɤ߹���
file_name = "tchar3.xml"
doc = nil
file = File.new(file_name)
doc = REXML::Document.new file
if doc
  body_str = XTDLNodeSearch(doc,eid,level)
else
  body_str = "<h3>Error!!,/h3>"
end

#��̽���
view(body_str.toutf8)
