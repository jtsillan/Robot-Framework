*** Settings ***
Variables    python_variables.py
Library      SeleniumLibrary
Library      Browser
Library      .venv/Lib/site-packages/robot/libraries/String.py
Library      .venv/Lib/site-packages/robot/libraries/Collections.py
Library      email_provider.py
Library      .venv/Lib/site-packages/robot/libraries/OperatingSystem.py

*** Variables ***
${COOKIES_DENY_BUTTON}    //*[@id="CybotCookiebotDialogBodyButtonDecline"]
${VISITOR_MENU}           //*[@id="visitor-menu"]
${LOG_IN}                 ${VISITOR_MENU}//*[contains(text(), "Kirjaudu sisään")]
${USER_NAME_INPUT}        //input[@name="username"]
${PASSWORD_INPUT}         //input[@name="password"]
${LOG_IN_DIALOG}          //*[@class="modal-content"]
${LOG_IN_BUTTON}          //input[@value="Kirjaudu sisään" and contains(@class, "login-submit")]
${LOGGED_IN_USER}         //*[@class="dropdown-toggle"]
${MAIN_MENU}              //*[@id="main-menu"]
${RESERVE_CLASS_TAB}      ${MAIN_MENU}//*[contains(text(), "Varaa tunti")]
${DATE_BOX}               //*[@class="date-box"]
${PILATES}                Hyvinvointipassi - Pilates
${JOOGA}                  Hyvinvointipassi - Jooga
@{CLASS_LIST}             ${PILATES}    ${JOOGA}
${FREE_CLASS}             fitness-event eventNormal
${FULL_CLASS}             fitness-event eventFull
${QUEUED_CLASS}           fitness-event eventQueued
${ATTENDING_CLASS}        fitness-event eventAttendance
${WIDTH}                  1500
${HEIGHT}                 800
${CONFIRM_BUTTON}         //*[contains(@class, "button-confirm")]
${POP_UP_CONTAINER}       //*[contains(@class, "popup-container")]
${LYY_TAB}                //*[@id="frontpage-tabs1"]//li[contains(text(), "LYY")]

*** Test Cases ***
Register To Pilates Class
    Open Browser And Log In    1
    Reserve Class
    [Teardown]    Wait And Close Browser

*** Keywords ***
Open Browser And Log In
    [Arguments]    ${round}
    SeleniumLibrary.Open Browser    https://vaki.fi/fi-fi    edge
    Set Window Size    ${WIDTH}    ${HEIGHT}
    Wait Until Element Is Visible    ${COOKIES_DENY_BUTTON}
    Click Element    ${COOKIES_DENY_BUTTON}
    Switch Window
    Click Log In Button    ${round}

Click Log In Button 
    [Arguments]    ${round}
    Log To Console   Click Log In Button >>> ROUND >>> ${round}
    FOR    ${x}    IN RANGE    5
    Log To Console    ******************************************** 
        Log To Console   Click Log In Button >>> COUNTER >>> ${x}
        Wait Until Element Is Visible    ${LOG_IN}
        Mouse Over    ${LOG_IN}
        Click Element    ${LOG_IN}    action_chain=${True}
        ${name_status}    Run Keyword And Return Status    Wait Until Element Is Visible    ${LOG_IN_DIALOG}
        Log To Console    Click Log In Button >>> status >>> ${name_status}
        IF    $name_status == $True             
            BREAK
        END
    END
    Log In As user    ${round}

Log In As user    
    [Arguments]    ${round}      
    FOR    ${y}    IN RANGE    5   
        Log To Console    ******************************************** 
        Log To Console   Log In As user >>> COUNTER >>> ${y}
        Mouse Over    ${USER_NAME_INPUT}
        Click Element    ${USER_NAME_INPUT}
        Input Text    ${USER_NAME_INPUT}    ${login_variables.user_name}
        Sleep    500 ms
        Wait Until Element Is Visible    ${PASSWORD_INPUT}
        Mouse Over    ${PASSWORD_INPUT}
        Click Element    ${PASSWORD_INPUT}
        Input Text    ${PASSWORD_INPUT}    ${login_variables.password}
        Sleep    500 ms
        Wait Until Element Is Enabled    ${LOG_IN_BUTTON}
        Mouse Over    ${LOG_IN_BUTTON}
        Click Element    ${LOG_IN_BUTTON}
        ${status}    Check Status    ${round}
        IF    $status == $True
            BREAK
        END
    END 

Check Status    
    [Arguments]    ${round}
    ${user_status}    Run Keyword And Return Status    Wait Until Element Contains    ${LOGGED_IN_USER}    ${login_variables.user}    timeout=10 s
    Log To Console   Check Status >>> user_status >>> ${user_status}
    IF    $user_status == $False
        ${round}      Evaluate    int(${round}) + 1
        IF    $round <= 3
            Log To Console   Check Status >>> ROUND >>> ${round}
            Close Browser And Try Again    ${round}
        ELSE
            Fail    Logging in was not succesfull after ${round} attempts.
        END  
    ELSE
        RETURN    ${user_status}
    END

Reserve Class
    Log To Console    ********************************************
    Log To Console    Reserve Class >>>
    &{data_dict}    Create Dictionary
    Mouse Over    ${RESERVE_CLASS_TAB}
    Click Element    ${RESERVE_CLASS_TAB}
    Wait Until Page Contains    Kalenteri    timeout=15 s
    Wait Until Keyword Succeeds    15 s    1 s    Select Frame    tag:iframe
    Wait Until Element Is Visible    ${LYY_TAB}
    Mouse Over    ${LYY_TAB}
    Click Element    ${LYY_TAB}
    # TODO: REPLACE SLEEP WITH LOAD COMPLETE
    Sleep    3 s
    FOR    ${index}    ${element}    IN ENUMERATE   @{CLASS_LIST}        
        Log To Console    Reserve Class >>> element >>> ${element}
        @{elements}    Get WebElements
        ...    //*[contains(@class,"swiper-slide-active")]//*[contains(text(), "${element}")]//ancestor::div[contains(@class,"fitness-event")]
        ${elements_numb}    Get Length    ${elements}
        &{element_dict}    Check Class Status    ${elements_numb}    ${element}   
        ${data_dict}[${element}]    Set Variable    ${element_dict}  
    END
    Send Email    ${data_dict}

Check Class Status
    [Arguments]    ${elements_numb}    ${name_element}
    Log To Console    Check Class Status >>> elements_numb >>> ${elements_numb}
    &{INFO_DICT}    Create Dictionary
    @{free_list}    Create List
    @{full_list}    Create List
    @{queue_list}    Create List
    @{attending_list}    Create List
    Log To Console    Check Class Status >>> INFO_DICT >>> ${INFO_DICT}
    FOR    ${index}    IN RANGE    ${elements_numb}
        Log To Console    Check Class Status >>> index >> ${index}
        @{element}    Get WebElements    
        ...    //*[contains(@class,"swiper-slide-active")]//*[contains(text(), "${name_element}")]//ancestor::div[contains(@class,"fitness-event")]          
        ${class_name}    Get Element Attribute    ${element}[${index}]    className
        Log To Console    Check Class Status >>> class_name >> ${class_name}
        IF    $class_name == $FREE_CLASS
            Log To Console    ********************************************
            Log To Console    Check Class Status >>> FREE CLASS --> START REGISTER 
            &{free_place}    Start Register    ${element}[${index}]
            Append To List    ${free_list}    ${free_place}
        END     
        IF    $class_name == $FULL_CLASS
            Log To Console    ********************************************
            Log To Console    Check Class Status >>> FULL CLASS --> CHECK QUEUE
            &{full_place}    Check Queue    ${element}[${index}]
            Append To List    ${full_list}    ${full_place}
            Log To Console    Check Class Status >>> queue_place >>> ${full_place}
        END    
        IF    $class_name == $QUEUED_CLASS
            Log To Console    ********************************************
            Log To Console    Check Class Status >>> QUEUED_CLASS --> CHECK QUEUE STATUS
            &{queue_place}    Check Queue Status    ${element}[${index}]
            Append To List    ${queue_list}    ${queue_place}
            Log To Console    Check Class Status >>> queue_place >>> ${queue_place}
        END      
        IF    $class_name == $ATTENDING_CLASS
            Log To Console    ********************************************
            Log To Console    Check Class Status >>> ATTENDING_CLASS --> Get Date From Attending Class
            @{attending_place}    Get Date From Attending Class    ${element}[${index}]
            Append To List    ${attending_list}    ${attending_place}
            Log To Console    Check Class Status >>> attending_place >>> ${attending_place}
        END     
    END   
    IF    $attending_list != []
        ${INFO_DICT}[AttendingClass]    Set Variable    ${attending_list}        
    END 
    IF    $queue_list != []
        ${INFO_DICT}[QueuedClass]    Set Variable    ${queue_list}        
    END
    IF    $free_list != []
        ${INFO_DICT}[FreeClass]    Set Variable    ${free_list}        
    END
    IF    $full_list != []
        ${INFO_DICT}[FullClass]    Set Variable    ${full_list}        
    END
    Log To Console    Check Class Status >>> INFO_DICT >>> ${INFO_DICT}
    RETURN    ${INFO_DICT}

Check Queue    
    [Arguments]    ${element}
    ${capacity}     Call Method    ${element}    find_element   by=xpath    value=child::*[@class="capacity"]
    ${date}    Call Method    ${element}    find_element    by=xpath    value=child::*[@class="date"]
    ${date_text}    SeleniumLibrary.Get Text    ${date}
    IF    $date_text != ""
        Log To Console    Check Queue >>> date_text >> ${date_text}           
    END
    ${text}    SeleniumLibrary.Get Text    ${capacity}
    IF    $text != ""
        Log To Console    Check Queue >>> text >> ${text}
        ${replace}    Replace String Using Regexp    ${text}    ['()'\'/']    ${EMPTY}
        Log To Console    Check Queue >>> replace >> ${replace}
        ${split}    Split String    ${replace}    ${SPACE}
        IF    ${split}[1] <= 10                
            Log To Console    Check Queue >>> split >> ${split}[1]
            Log To Console    Check Queue >>> Start Register
            ${register_dict}    Start Register    ${element}    ${date}
            RETURN    ${register_dict}
        ELSE
            #Log To Console    Check Queue >>> CLASS IS TOO FULL
            #TODO: SHOULD BE IN ABOVE IF CLAUSE
            Log To Console    Check Queue >>> split >> ${split}[1]
        END
    END

Start Register
    [Arguments]    ${element}    ${date}=${None}
    &{dict}    Create Dictionary
    IF    $date == $None    
        ${date}    Call Method    ${element}    find_element    by=xpath    value=child::*[@class="date"]
    END
    ${date_text}    SeleniumLibrary.Get Text    ${date}
    Click Element    ${date}        
    Wait Until Page Contains Element    ${CONFIRM_BUTTON}
    Scroll Element Into View    ${CONFIRM_BUTTON}
    Mouse Over    ${CONFIRM_BUTTON}
    Click Element    ${CONFIRM_BUTTON}
    Wait Until Element Is Visible    ${POP_UP_CONTAINER}    timeout=10s
    Wait Until Element Is Not Visible    ${POP_UP_CONTAINER}    timeout=10s
    ${queue_place}    Check Button Text
    Set To Dictionary    ${dict}    ${date_text}=${queue_place}
    Go Back To Calendar
    Log To Console    *********************START REGISTER ENDS************************
    RETURN    &{dict}

Check Queue Status
    [Arguments]    ${element}
    &{dict}    Create Dictionary
    ${date}    Call Method    ${element}    find_element    by=xpath    value=child::*[@class="date"]
    ${date_text}    SeleniumLibrary.Get Text    ${date}
    IF    $date_text != ""
        Log To Console    Check Queue Status >>> date_text >> ${date_text}           
    END
    Click Element    ${date}
    ${queue_place}    Check Button Text
    Set To Dictionary    ${dict}    ${date_text}=${queue_place}
    Go Back To Calendar
    Log To Console    *********************Check Queue Status ENDS************************
    RETURN    &{dict}

Check Button Text
    ${status}    Run Keyword And Return Status    
    ...    Wait Until Element Is Visible    
    ...    locator=//*[@class="handle-event"]//*[contains(@class, "button-confirm")]    
    ...    timeout=10s
    IF    $status == $True
        ${text}    SeleniumLibrary.Get Text    //*[@class="handle-event"]//*[contains(@class, "button-confirm")]
        Log To Console    Check Button Text >>> text >> ${text}  
        Should Contain    ${text}    OLET JONOSSA PAIKALLA
        ${extract}    Fetch From Right    ${text}    ${SPACE}
        Log To Console    Check Button Text >>> extract >> ${extract}  
    ELSE
        ${text}    SeleniumLibrary.Get Text    //*[@class="capacity ng-binding"]
        Log To Console    Check Button Text >>> text >> ${text} 
        ${strip}    Strip String    ${text}
        Log To Console    Check Button Text >>> strip >> ${strip}
        ${extract}    Fetch From Left    ${text}    ${SPACE}
        Log To Console    Check Button Text >>> extract >> ${extract} 
    END
    RETURN    ${extract}

Go Back To Calendar
    Log To Console    Go Back To Calendar >>>     
    #Scroll Element Into View    //ion-header-bar//*[@class="back-text"]/*[contains(text(), "Kalenteri")]//ancestor::button
    FOR    ${counter}    IN RANGE    6
        Log To Console    Go Back To Calendar >>> counter >> ${counter}
        Mouse Over    //ion-header-bar//*[@class="back-text"]/*[contains(text(), "Kalenteri")]//ancestor::button
        ${status}    Run Keyword And Return Status    Click Element    //ion-header-bar//*[@class="back-text"]/*[contains(text(), "Kalenteri")]//ancestor::button
        Log To Console    Go Back To Calendar >>> status >> ${status}
        IF    ${status} == $False
            FOR    ${counter}    IN RANGE    3
                SeleniumLibrary.Press Keys    ${None}    ARROW_UP                   
            END
        ELSE
            BREAK        
        END
    END

Get Date From Attending Class
    [Arguments]    ${element}
    Log To Console    Get Date From Attending Class >>>  
    @{date_list}    Create List
    ${date}    Call Method    ${element}    find_element    by=xpath    value=child::*[@class="date"]
    ${date_text}    SeleniumLibrary.Get Text    ${date}
    Append To List    ${date_list}    ${date_text}
    RETURN    ${date_list}

Wait And Close Browser
    Sleep    2s
    SeleniumLibrary.Close Browser

Close Browser And Try Again
    [Arguments]    ${counter}
    Wait And Close Browser
    Open Browser And Log In    ${counter}
    Reserve Class