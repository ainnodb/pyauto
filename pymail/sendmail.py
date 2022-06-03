import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.header import Header

#邮件服务器信息
smtp_server = "smtp.qq.com"
port = 465  # For starttls
sender_email = "250122562@qq.com"
password=""  #get password from mailsetting

#发送邮件信息,可以发送给多个收件人
receivers=["250122462@163.com","motingxia@163.com"]
subject="This is import Python SMTP 邮件(文件传输) 多媒体测试"

# message = MIMEText(text, "plain", "utf-8") #文本邮件
message = MIMEMultipart()
message["Subject"] = Header(subject, "utf-8")
message["from"] = sender_email
message["to"] = ",".join(receivers)
# 邮件正文内容
text="""
Dear Sir:
how are you ? \n
for detail information pls refer to attach1。\n
The files you need are as followed.\n
If you have any concern pls let me known.\n
enjoy your weekend.\n
BEST REGARDS \n
"""
# message.attach(MIMEText('for detail information pls refer to attach1。\n The files you need are as followed. \n If you have any concern pls let me known. \n enjoy your weekend', 'plain', 'utf-8')
message.attach(MIMEText(text,'plain','utf-8'))

# 构造附件1
attach_file1='IMG_3159.JPG'

attach1 = MIMEText(open(attach_file1, 'rb').read(), 'base64', 'utf-8')
attach1["Content-Type"] = 'application/octet-stream'
attach1["Content-Disposition"] = 'attachment; filename={0}'.format(attach_file1)
message.attach(attach1)

# 构造附件2
attach_file2='IMG_3160.JPG'
attach2 = MIMEText(open(attach_file2, 'rb').read(), 'base64', 'utf-8')
attach2["Content-Type"] = 'application/octet-stream'
attach2["Content-Disposition"] = 'attachment; filename={0}'.format(attach_file2)
message.attach(attach2)

# Try to log in to server and send email
# server = smtplib.SMTP_SSL(smtp_server,port)
server = smtplib.SMTP_SSL(smtp_server,port)

try:
    server.login(sender_email, password)
    server.sendmail(sender_email,receivers,message.as_string())
    print("邮件发送成功!!!")
    print("Mail with {0} & {1} has been send to {2} successfully.".format(attach_file1,attach_file2,receivers))
except Exception as e:
    # Print any error messages to stdout
    print("Error: 无法发送邮件")
    print(e)
finally:
    server.quit()