#!/usr/bin/ruby

require 'cgi'
require "kconv"
require "rexml/document"
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
  ques_buff = ""
  obj_buff = ""
  make_buff = ""
  hint_buff = ""
  ts_buff = ""
  
  if dom_obj.name["group"] #group���Ǥʤ��
    
    if dom_obj.attributes["id"] == eid
      dom_obj.each_element do |elem|
        
        if elem.attributes["id"] != ""
          #�������Ѥ�ID����
          if elem.name["q"]
            ques_buff += elem.attributes["id"]
            #���֥������ȥ���������Ѥ�ID����
          elsif elem.name["o"]
            obj_buff += elem.attributes["id"]
            #makefile����������Ѥ�ID����
          elsif elem.name["m"]
            make_buff += elem.attributes["id"]
            #�ҥ�����Ѥ�ID�����
          elsif elem.name["h"] 
            if elem.attributes["level"] == "all" 
              hint_buff += elem.attributes["id"]
            elsif elem.attributes["level"].to_i == level
              hint_buff += "," + elem.attributes["id"]
            end
            #�ƥ��ȥ���������Ѥ�ID����
          elsif elem.name["t"]
            ts_buff = elem.attributes["id"]
          else
          end
        end
      end

      #������󼨤��뤿���ID������������
      ques = ques_buff.split(',')
      print "����"
      print ques
      #���֥������Ȥ��������ɤ��뤿���ID������������
      if obj_buff.length !=0
        obj = obj_buff.split(',')
        print "���֥�������"
        print obj
      end
      #makefile���������ɤ��뤿���ID������������
      if make_buff.length != 0
        make = make_buff.split(',')
        print "�᡼���ե�����"
        print make
      end
      #�ҥ�Ȥ��󼨤��뤿���ID������������
      hints = hint_buff.split(',')
      print "�ҥ��"
      print hints
      #�ƥ��Ȥ��������ɤ��뤿���ID������������
      if ts_buff.length != 0
        ts = ts_buff.split(',')
        print "�ƥ���"
        print ts
      end
      
    end
    


##��ID�γ�Ǽ�ꥹ��̾
#
#����         :ques
#���֥������� :obj
#makefile     :make
#�ҥ��       :hints
#�ƥ��ȥǡ��� :ts
###

  elsif dom_obj.name["download"] #download���Ǥʤ��

  elsif dom_obj.name["question"] #question���Ǥʤ��

  elsif dom_obj.name["source"] #source���Ǥʤ��

  else
    
  end

  return str_buff
end



#�Ƶ�Ū�˥Ρ��ɤ򸡺�
def XTDLNodeSearch(dom_obj,eid,level)
  #��̣��������
  semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation","exercise"]
  
  
  str_buff = ""
  flag = false #Ƚ��ե饰
  if dom_obj.name["xtdl"] # xtdl���Ǥʤ��
    str_buff += "���å����ƥ��ǥ�������"
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["section"] # section���Ǥʤ��
    str_buff += "���������"
    if dom_obj.attributes["title"] != ""
      str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h2>"
    else
      str_buff += "<br /><br />"
    end
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["exercise"] #exercise���Ǥʤ��
    str_buff += "������������"
    dom_obj.each_element do |elem|
      str_buff += ExerciseRead(elem,eid,level)
    end
  else # ��̣���Ǥʤ��
    str_buff += "��̣����"
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
      str_buff += "ư���ǧ"
      dom_obj.each_element do |elem|
        str_buff += XTDLNodeSearch(elem,eid,level)
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
  body_str = XTDLNodeSearch(doc.root,eid,level)
else
  body_str = "<h3>Error!!,/h3>"
end

#��̽���
view(body_str.toutf8)
