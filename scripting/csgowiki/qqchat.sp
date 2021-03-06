// 

public Action:Command_QQchat(client, args) {
    if (!GetConVarBool(g_hChannelEnable)) {
        PrintToChat(client, "%s \x02qq聊天已关闭，请联系服务器管理员", PREFIX);
        return;
    }
    if (g_bQQTrigger[client]) {
        PrintToChat(client, "%s \x09当前QQ聊天触发模式为 \x04打字触发\x09，不必要使用该指令，可在!option中修改设置");
        return;
    }
    char words[LENGTH_MESSAGE];
    char name[LENGTH_NAME];
    GetClientName(client, name, sizeof(name));
    GetCmdArgString(words, sizeof(words));
    TrimString(words);
    MessageToQQ(client, name, words);
}

void MessageToQQ(int client, char[] name, char[] words, int msg_type=0) {
    if (strlen(words) == 0) {
        if (IsPlayer(client)) {
            PrintToChat(client, "%s \x02不能发送空内容", PREFIX);
        }
        return;
    }
    char remark[LENGTH_NAME];
    char qqgroup[LENGTH_NAME];
    char svHost[LENGTH_IP];
    char token[LENGTH_TOKEN]
    int svPort = GetConVarInt(g_hChannelSvPort);
    GetServerHost(svHost, LENGTH_IP);
    GetConVarString(g_hChannelServerRemark, remark, sizeof(remark));
    GetConVarString(g_hChannelQQgroup, qqgroup, sizeof(qqgroup));
    GetConVarString(g_hCSGOWikiToken, token, sizeof(token))

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        MessageToQQCallback,
        "https://service-mxw8pitd-1256946954.cd.apigw.tencentcs.com/release/api/to_qq"
    );

    httpRequest.SetData(
        "sv_remark=%s&qq_group=%s&sender=%s&message=%s&msg_type=%d&sv_host=%s&sv_port=%d&token=%s",
        remark, qqgroup, name, words, msg_type, svHost, svPort, token
    );
    httpRequest.Any = client;
    httpRequest.POST();
    delete httpRequest;
}

public MessageToQQCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        int client = request.Any;
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (!StrEqual(status, "ok")) {
            if (IsPlayer(client)) {
                PrintToChat(client, "%s \x02未能成功发送消息", PREFIX);
            }
        }
        else {
            if (IsPlayer(client)) {
                PrintToChat(client, "%s \x06消息发送成功", PREFIX);
            }
        }
        json_cleanup_and_delete(json_obj);
    }
}

void TcpCreate() {
    char remark[LENGTH_NAME];
    char qqgroup[LENGTH_NAME];
    char svHost[LENGTH_IP];
    char token[LENGTH_TOKEN];
    int svPort = GetConVarInt(g_hChannelSvPort);
    GetServerHost(svHost, LENGTH_IP);
    GetConVarString(g_hChannelServerRemark, remark, sizeof(remark));
    GetConVarString(g_hChannelQQgroup, qqgroup, sizeof(qqgroup));
    GetConVarString(g_hCSGOWikiToken, token, sizeof(token));

    if (strlen(qqgroup) == 0 || strlen(svHost) == 0 || strlen(remark) == 0) {
        PrintToServer("群号或主机信息获取失败");
        PrintToChatAll("%s \x02QQ或主机获取失败", PREFIX);
        return;
    }

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        TcpCreateCallback,
        "https://service-mxw8pitd-1256946954.cd.apigw.tencentcs.com/release/api/tcp_create"
    );
    httpRequest.SetData(
        "sv_remark=%s&qq_group=%s&sv_host=%s&sv_port=%d&token=%s",
        remark, qqgroup, svHost, svPort, token
    );
    httpRequest.POST();
    delete httpRequest;
}

public TcpCreateCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "error")) {
            PrintToChatAll("%s \x02消息通道建立失败", PREFIX);
        }
        else if (StrEqual(status, "ok")){
            PrintToServer("%s \x06消息通道建立成功", PREFIX);
        }
        json_cleanup_and_delete(json_obj);
    }
}

void TcpClose() {
    char remark[LENGTH_NAME];
    char qqgroup[LENGTH_NAME];
    char svHost[LENGTH_IP];
    char token[LENGTH_TOKEN]
    GetServerHost(svHost, LENGTH_IP);
    GetConVarString(g_hChannelServerRemark, remark, sizeof(remark));
    GetConVarString(g_hChannelQQgroup, qqgroup, sizeof(qqgroup));
    GetConVarString(g_hCSGOWikiToken, token, sizeof(token))

    System2HTTPRequest httpRequest = new System2HTTPRequest(
        TcpCloseCallback,
        "https://service-mxw8pitd-1256946954.cd.apigw.tencentcs.com/release/api/tcp_close"
    );

    httpRequest.SetData(
        "sv_remark=%s&qq_group=%s&sv_host=%s&token=%s",
        remark, qqgroup, svHost, token
    );
    httpRequest.POST();
    delete httpRequest;
}

public TcpCloseCallback(bool success, const char[] error, System2HTTPRequest request, System2HTTPResponse response, HTTPRequestMethod method) {
    if (success) {
        char[] status = new char[LENGTH_STATUS];
        char[] content = new char[response.ContentLength + 1];
        response.GetContent(content, response.ContentLength + 1);
        JSON_Object json_obj = json_decode(content);
        json_obj.GetString("status", status, LENGTH_STATUS);
        if (StrEqual(status, "error")) {
            PrintToChatAll("%s \x02消息通道关闭失败", PREFIX);
        }
        else if (StrEqual(status, "ok")){
            PrintToServer("%s \x06消息通道关闭成功", PREFIX);
        }
        json_cleanup_and_delete(json_obj);
    }
}

public Action:TcpHeartBeat(Handle timer) {
    TcpCreate();
}

public Action OnSocketIncoming(Handle socket, Handle newSocket, char[] remoteIP, int remotePort, any arg) {
	// setup callbacks required to 'enable' newSocket
	// newSocket won't process data until these callbacks are set
	SocketSetReceiveCallback(newSocket, OnChildSocketReceive);
	SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnected);
	SocketSetErrorCallback(newSocket, OnChildSocketError);
	// SocketSend(newSocket, "send quit to quit\n");
}

public Action OnSocketError(Handle socket, const int errorType, const int errorNum, args) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public Action OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile) {
	// send (echo) the received data back
    JSON_Object json_obj = json_decode(receiveData);
    char sender[LENGTH_NAME];
    char message[LENGTH_MESSAGE];
    int msg_type = json_obj.GetInt("msg_type");
    json_obj.GetString("sender", sender, sizeof(sender));
    json_obj.GetString("message", message, sizeof(message));

    if (msg_type == 0) {
        PrintToChatAll("[\x09QQ\x01] \x04%s\x01：%s", sender, message);
        PrintToServer("[QQ] \x04%s\x01：%s", sender, message);
    }
    else if (msg_type == 1) {
        char monitor_str[LENGTH_SERVER_MONITOR];
        JSON_Array monitor_json = encode_json_server_monitor(-2, false, false, true);
        monitor_json.Encode(monitor_str, LENGTH_SERVER_MONITOR);
        MessageToQQ(-1, "Bot", monitor_str, 1);
    }
    else if (msg_type == 2) {
        char monitor_str[LENGTH_SERVER_MONITOR];
        JSON_Array monitor_json = encode_json_server_monitor(-2, false, false, true, true);
        monitor_json.Encode(monitor_str, LENGTH_SERVER_MONITOR);
        SocketSend(socket, monitor_str);
    }
    json_cleanup_and_delete(json_obj);
	// SocketSend(socket, receiveData);
	// close the connection/socket/handle if it matches quit
	// if (strncmp(receiveData, "quit", 4) == 0) CloseHandle(socket);
}

public Action OnChildSocketDisconnected(Handle socket, args) {
	// remote side disconnected
	CloseHandle(socket);
}

public Action OnChildSocketError(Handle socket, const int errorType, const int errorNum, any ary) {
	// a socket error occured
	LogError("child socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}