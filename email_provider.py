import smtplib, ssl, random, dominate
from dominate.tags import *
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from python_variables import GmailCredentials, LoginVariables
from robot.api import logger


def send_email(text):
    logger.console(f"send_email() >>> text >> {text}")
    html_msg = parse_email_text(text_dict=text)
    sender_email = GmailCredentials.email
    receiver_email = LoginVariables.user_name
    msg = MIMEMultipart()
    msg['Subject'] = "Väen Pilates ja Jooga tunnit"
    msg['From'] = sender_email
    msg['To'] = receiver_email
    msg.attach(MIMEText(html_msg, "html"))
    #msg.set_content(html_msg)
    context = ssl.create_default_context()
    with smtplib.SMTP_SSL('smtp.gmail.com', 465, context=context) as server:
        server.login(GmailCredentials.email, GmailCredentials.password)
        server.sendmail(receiver_email, receiver_email, msg.as_string())
        server.quit()      
        
           
def parse_email_text(text_dict):
    # TODO: PARSE DICTIONARY
    document = dominate.document(title="EMAIL")
    logger.console(f"parse_email_text() >>> document >> {document}") 
    
    with document:
        for outer_key, outer_value in text_dict.items():
            logger.console(f"parse_email_text() >>> outer_key >> {outer_key}") 
            logger.console(f"parse_email_text() >>> outer_value >> {outer_value}")
            with div():
                attr(cls="body")
                h1(outer_key)
            logger.console(f"parse_email_text() >>> document >> {document}") 
            for inner_key, inner_value in outer_value.items():
                logger.console(f"parse_email_text() >>> inner_key >> {inner_key}")
                logger.console(f"parse_email_text() >>> inner_value >> {inner_value}")
                if inner_key == "AttendingClass":
                    with div():
                        p("Osallistut seuraaville tunneille:")
                elif inner_key == "QueuedClass":
                    with div():
                        p("Olet jonossa seuraaville tunneille:")
                elif inner_key == "FreeClass":
                    with div():
                        p("Ilmoittauminen onnistui seuraaville tunneille:")
                elif inner_key == "FullClass":
                    with div():
                        p("Ilmoittauduit jonossa sijalle 10")
                # inner_value is a list containing dictionaries --> 
                logger.console(f"parse_email_text() >>> document >> {document}") 
                for inner_list in inner_value:                
                    logger.console(f"parse_email_text() >>> inner_list >> {inner_list}")
                    if type(inner_list) is not list:
                        logger.console(f"parse_email_text() >>> not a list") 
                        for k, v in inner_list.items():  
                            logger.console(f"parse_email_text() >>> k >> {k}")    
                            logger.console(f"parse_email_text() >>> v >> {v}")     
                            with table().add(tbody()):
                                with tr():
                                    td("Aika: ", k)
                                    td("Sijaluku: ", v)
                    else:
                        logger.console(f"parse_email_text() >>> a list")
                        for inner_item in inner_list:
                            with table().add(tbody()):
                                with tr():
                                    td("Aika: ", inner_item)
                                
                                
    logger.console(f"parse_email_text() >>> document >> {document}")   
                
    return document.render()
