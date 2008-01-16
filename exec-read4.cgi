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
  
  #�������Ƥ�񤭹��ि��˥ե�����򳫤�
  out_q = open("question.txt","w")
  #�������ե������ѤΥ����ɤ�񤭹��ि��Υե�����򳫤�
  out_s = open("source.txt","w")

  dom_obj.each_element do |elem|

    if elem.name["group"] #group���Ǥʤ��
      
      if elem.attributes["id"] == eid
        elem.each_element do |el|
          
          if el.attributes["id"] != ""
            #�������Ѥ�ID����
            if el.name["q"]
              ques_buff += el.attributes["id"]
              #���֥������ȥ���������Ѥ�ID����
            elsif el.name["o"]
              obj_buff += el.attributes["id"]
              #makefile����������Ѥ�ID����
            elsif el.name["m"]
              make_buff += el.attributes["id"]
              #�ҥ�����Ѥ�ID�����
            elsif el.name["h"] 
              if el.attributes["level"] == "all" 
                hint_buff += el.attributes["id"]
              elsif el.attributes["level"].to_i == level
                hint_buff += "," + el.attributes["id"]
              end
              #�ƥ��ȥ���������Ѥ�ID����
            elsif el.name["t"]
              ts_buff = el.attributes["id"]
            end
          end
        end


        #���֥������Ȥ��������ɤ��뤿���ID������������
        if elem.length !=0
          obj = obj_buff.split(',')
          # print "���֥�������"
          # print obj
        end
        #makefile���������ɤ��뤿���ID������������
        if make_buff.length != 0
          make = make_buff.split(',')
          #print "�᡼���ե�����"
          #print make
        end


        #�ƥ��Ȥ��������ɤ��뤿���ID������������
        if ts_buff.length != 0
          ts = ts_buff.split(',')
          #print "�ƥ���"
          #print ts
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

    elsif elem.name["download"] #download���Ǥʤ��
    elsif elem.name["question"] #question���Ǥʤ��
      #������󼨤��뤿���ID������������
      ques = ques_buff.split(',')
      for i in ques
        #id�����פ�������ε������Ƥ�õ���Ф�
        if elem.attributes["id"] == i
          out_q.print(elem.text)
          str_buff += elem.text.gsub("\n","<br>")
          #str_buff.gsub('\n',"<br>")
        end
      end
    elsif elem.name["source"] #source���Ǥʤ��
      #�ҥ�Ȥ��󼨤��뤿���ID������������
      num = 1
      hints = hint_buff.split(',')
      elem.each_element do |el|
        #�����Ǥ�item�ʤ�
        if el.name["item"]
          #fg = false
          for i in hints
            #id�����פ�����ΤΥƥ����Ȥ���Ф�
            if el.attributes["id"] ==i
                  #���̤�ɽ��������
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
          #�����Ǥ�comment�ʤ�
        elsif el.name["comment"]
        end
      end
    end
  end
  #�񤭹����ѥե�����Υ�����
  out_q.close
  out_s.close
  return str_buff
end


#�Ƶ�Ū�˥Ρ��ɤ򸡺�
def XTDLNodeSearch(dom_obj,eid,level)
  #��̣��������
  semantic_elem_array = ["explanation","example","illustration","definition","program","algorithm","proof","simulation","exercise"]
  
  
  str_buff = ""
  flag = false #Ƚ��ե饰
  if dom_obj.name["xtdl"] # xtdl���Ǥʤ��
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["section"] # section���Ǥʤ��
    if dom_obj.attributes["title"] != ""
      str_buff += "<h2>" + dom_obj.attributes["title"].toutf8 + " <span style=\"color:red\">ID : " + dom_obj.attributes["id"].toutf8 + "</span></h2>"
    else
      str_buff += "<br /><br />"
    end
    dom_obj.each_element do |elem|
      str_buff += XTDLNodeSearch(elem,eid,level)
    end
    
  elsif dom_obj.name["exercise"] #exercise���Ǥʤ��
    str_buff += "<b>�齬����</b><p>"
    str_buff += ExerciseRead(dom_obj,eid,level)
    str_buff += "</p>"
  else # ��̣���Ǥʤ��
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

cgi = CGI.new
str_buff = ""

# Form�����ͤΥ����å�
src_name = cgi["src_name"]
dir_name = "/work/"#cgi["dir"]
id = "1"#cgi["id"]
eid = cgi["eid"]
level = cgi["lebel"]
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

#�ե������ɤ߹���
file_name = src_name
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
