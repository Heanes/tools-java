<%--
  @doc 生成mysql数据字典
  @author fanggang
  @time: 2015-11-24 19:11:24
--%>
<%@page contentType="text/html;charset=UTF-8" language="java"%>
<%@page import="java.util.*"%>
<%@page import="java.sql.*"%>
<%@page import="java.text.NumberFormat"%>
<%
    class Table{
        public String tableName;        //表名
        public String tableComment;     //表注释
        public String columnName;       //字段名
        public String columnType;       //字段类型
        public String columnComment;    //字段注释
        public String isNullable;       //是否可空
        public String columnKey;        //键类型,主键/外键
        public String extra;            //自增起其他属性
        public String columnDefault;    //默认值
        public String characterSetName; //字符集
        public String tableCollation;   //表排序规则
        public String collationName;    //字段排序规则
        public Long   ordinalPosition;  // 字段在表中序号
        public Long   autoIncrement;    // 表自增值
        public String createTime;       // 创建时间
    }
    String path = request.getContextPath();
    String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path;
    String baseUrl = basePath + request.getContextPath() + request.getServletPath();

    Boolean isSetSession = false;
    Boolean isSetCookie = false;
    Boolean isSetGet = false;
    Boolean connectWrong = true;

    // 获取cookie,检测cookie中是否存在配置,且没有记录连接错误的信息
    Cookie[] cookies = request.getCookies();
    if (cookies != null && cookies.length > 0) {
        for (Cookie cookie : cookies) {
            if(cookie.getName() != null){
                ;
            }
        }
    }else{
        isSetCookie = false;
    }

    Map<String, String> configMap = new HashMap<String, String>();
    configMap.put("server",     "localhost");
    configMap.put("port",       "3307");
    configMap.put("dataBase",   "tmc");
    configMap.put("userName",   "root");
    configMap.put("password",   "123456");
    Map<String, String> tmpConfig = configMap;

    Map<String, List<Table>> tableMap = new HashMap<String, List<Table>>();
    Map<String, List<Table>> tableSortedMap = new HashMap<String, List<Table>>();

    String title = "数据字典";
    // 1.原生java request对象获取url中的参数
    String queryString = request.getQueryString();

    // 从cookie中取配置
    if(!"config".equals(queryString) && !"postConfig".equals(queryString) && !"mysqlConnectError".equals(queryString) && !"deleteSuccess".equals(queryString)){
        //1，检测session或cookie中是否存有数据库配置
        //1.1 若无，跳转到?config地址，让用户输入数据库配置
        if(!isSetGet && !isSetSession && !isSetCookie || connectWrong){
            response.sendRedirect(baseUrl + "?config");
            return;
        }else{
            //1.2 若有，则根据配置查看数据字典页
            if(isSetCookie){
                ;
            }else{

            }
            // 1.3 也可以在url中指定配置，但URL只是暂时配置，不存入session或cookie
            if(isSetGet){
                ;
            }
        }
    }
    // 2.原生java 接受ajax提交的信息,按提交配置尝试连接
    if("postConfig".equals(queryString)){

        String user     = request.getParameter("dbUser");
        String password = request.getParameter("dbPassword");
        String server   = request.getParameter("dbServer");
        String host     = request.getParameter("dbHost");
        String port     = request.getParameter("dbPort");
        try {
            // 3.原生java 连接数据库并执行sql查询
            Class.forName("com.mysql.jdbc.Driver");//.newInstance();
            String mysqlConnectUrl = "jdbc:mysql://" + configMap.get("server") + ":" +configMap.get("port") + "/" + configMap.get("dataBase")
                                        + "?user=" + configMap.get("userName") + "&password=" + configMap.get("password") + "&useUnicode=true&characterEncoding=UTF8" ;
            Connection conn= DriverManager.getConnection(mysqlConnectUrl);
            if(conn.isClosed()){
                out.print("数据库连接不成功!");
                out.print(conn.getWarnings());
                return;
            }else{
                // 3.原生java 保存信息到cookie或session中
                request.setAttribute("_db_config", configMap);
                request.setAttribute("_db_connect_errno", null);
                request.setAttribute("_db_connect_error", null);

                title += "-" + configMap.get("dataBase") + "@" + configMap.get("server") + " on " + configMap.get("port") + " - " + configMap.get("userName");
            }
            //out.print(request.getSession());
            Statement stmt=conn.createStatement();
            String sql = "SELECT T.TABLE_NAME AS TABLE_NAME, TABLE_COMMENT, COLUMN_NAME, COLUMN_TYPE, COLUMN_COMMENT, IS_NULLABLE, COLUMN_KEY, COLUMN_KEY, EXTRA, COLUMN_DEFAULT,"
                    + " CHARACTER_SET_NAME, TABLE_COLLATION, COLLATION_NAME, ORDINAL_POSITION, AUTO_INCREMENT, CREATE_TIME"
                    + " FROM INFORMATION_SCHEMA.TABLES AS T"
                    + " JOIN INFORMATION_SCHEMA.COLUMNS AS C ON T.TABLE_SCHEMA = C.TABLE_SCHEMA AND C.TABLE_NAME = T.TABLE_NAME"
                    + " WHERE T.TABLE_SCHEMA = '" + configMap.get("dataBase") + "' ORDER BY T.TABLE_NAME, ORDINAL_POSITION";
            ResultSet result = stmt.executeQuery(sql);
            while(result.next()){
                String tableName = result.getString("TABLE_NAME");
                Table table = new Table();
                table.tableName         = tableName;
                table.tableComment      = result.getString("TABLE_COMMENT");
                table.columnName        = result.getString("COLUMN_NAME");
                table.columnType        = result.getString("COLUMN_TYPE");
                table.columnComment     = result.getString("COLUMN_COMMENT");
                table.isNullable        = result.getString("IS_NULLABLE");
                table.columnKey         = result.getString("COLUMN_KEY");
                table.extra             = result.getString("EXTRA");
                table.columnDefault     = result.getString("COLUMN_DEFAULT");
                table.characterSetName  = result.getString("CHARACTER_SET_NAME");
                table.tableCollation    = result.getString("TABLE_COLLATION");
                table.collationName     = result.getString("COLLATION_NAME");
                table.ordinalPosition   = result.getLong("ORDINAL_POSITION");
                table.autoIncrement     = result.getLong("AUTO_INCREMENT");
                table.createTime        = result.getString("CREATE_TIME");
                if(tableMap.get(tableName) != null && tableMap.get(tableName).size() > 0){
                    tableMap.get(tableName).add(table);
                }else{
                    List<Table> tableGroupList = new ArrayList<Table>();
                    tableGroupList.add(table);
                    tableMap.put(tableName, tableGroupList);
                }
            }

            sql = "SELECT T.TABLE_NAME AS TABLE_NAME, TABLE_COMMENT, COLUMN_NAME, COLUMN_TYPE, COLUMN_COMMENT, IS_NULLABLE, COLUMN_KEY, COLUMN_KEY, EXTRA, COLUMN_DEFAULT,"
                + " CHARACTER_SET_NAME, TABLE_COLLATION, COLLATION_NAME, ORDINAL_POSITION, AUTO_INCREMENT, CREATE_TIME"
                + " FROM INFORMATION_SCHEMA.TABLES AS T"
                + " JOIN INFORMATION_SCHEMA.COLUMNS AS C ON T.TABLE_SCHEMA = C.TABLE_SCHEMA AND C.TABLE_NAME = T.TABLE_NAME"
                + " WHERE T.TABLE_SCHEMA = '" + configMap.get("dataBase") + "' ORDER BY T.TABLE_NAME, COLUMN_NAME";
            result = stmt.executeQuery(sql);
            while(result.next()){
                String tableName = result.getString("TABLE_NAME");
                Table table = new Table();
                table.tableName         = tableName;
                table.tableComment      = result.getString("TABLE_COMMENT");
                table.columnName        = result.getString("COLUMN_NAME");
                table.columnType        = result.getString("COLUMN_TYPE");
                table.columnComment     = result.getString("COLUMN_COMMENT");
                table.isNullable        = result.getString("IS_NULLABLE");
                table.columnKey         = result.getString("COLUMN_KEY");
                table.extra             = result.getString("EXTRA");
                table.columnDefault     = result.getString("COLUMN_DEFAULT");
                table.characterSetName  = result.getString("CHARACTER_SET_NAME");
                table.tableCollation    = result.getString("TABLE_COLLATION");
                table.collationName     = result.getString("COLLATION_NAME");
                table.ordinalPosition   = result.getLong("ORDINAL_POSITION");
                table.autoIncrement     = result.getLong("AUTO_INCREMENT");
                table.createTime        = result.getString("CREATE_TIME");
                if(tableSortedMap.get(tableName) != null && tableSortedMap.get(tableName).size() > 0){
                    tableSortedMap.get(tableName).add(table);
                }else{
                    List<Table> tableGroupList = new ArrayList<Table>();
                    tableGroupList.add(table);
                    tableSortedMap.put(tableName, tableGroupList);
                }
            }

            if(result != null)result.close();
            if(stmt != null)stmt.close();
            if(conn != null)conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            out.print(e.getMessage());
        }
    }

    if("config".equals(queryString)){
        title = "填写数据库配置";
    }
    if("mysqlConnectError".equals(queryString)){
        title = "数据库连接错误，请重新检查数据库信息后填写数据库配置！";
    }
    if("deleteSuccess".equals(queryString)){
        title = "已经成功删除保存的配置信息！";
    }

%>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
    <meta name="renderer" content="webkit"/>
    <meta name="author" content="Heanes heanes.com email(heanes@163.com)"/>
    <title><%=title%></title>
    <style>
        *{box-sizing:border-box}
        body{padding:0;margin:0;}
        body,td,th {font:14px/1.3 TimesNewRoman,Arial,Verdana,tahoma,Helvetica,sans-serif}
        ::-webkit-scrollbar-track{box-shadow:inset 0 0 6px rgba(0,0,0,0.3);-webkit-box-shadow:inset 0 0 6px rgba(0,0,0,0.3);-webkit-border-radius:10px;border-radius:10px}
        ::-webkit-scrollbar{width:6px;height:5px}
        ::-webkit-scrollbar-thumb{-webkit-border-radius:10px;border-radius:10px;background:rgba(0,0,0,0.39);}
        .w-wrap{width:1065px;margin:0 auto;}
        .fixed{position:fixed;}
        .toolbar-block{width:100%;top:0;right:0;height:38px;background-color:rgba(31,31,31,0.73);-webkit-box-shadow:0 3px 6px rgba(0,0,0,.2);-moz-box-shadow:0 3px 6px rgba(0,0,0,.2);box-shadow:0 3px 6px rgba(0,0,0,.2);z-index:100;}
        .toolbar-block-placeholder{height:40px;width:100%;}
        .operate-db-block{position:relative;}
        .absolute-block{position:absolute;right:0;font-size:0;top:0;}
        .toolbar-button-block,.toolbar-input-block{display:inline-block;}
        .toolbar-input-block{height:38px;line-height:36px;}
        .toolbar-input-label{color:#fff;background-color:#5b5b5b;display:inline-block;height:38px;padding:0 4px;}
        .toolbar-input-block .toolbar-input{width:300px;height:36px;margin:0 8px;}
        .toolbar-input-block.search-input{padding:0 4px;position:relative}
        .search-result-summary{position:absolute;right:16px;top:2px;font-size:13px;color:#999;}
        .change-db{background-color:#1588d9;border-color:#46b8da;color:#fff;margin-bottom:0;font-size:14px;font-weight:400;}
        .change-db:hover{background-color:#337ab7}
        .hide-tab,.hide-tab-already{background-color:#77d26d;color:#fff;}
        .hide-tab:hover,.hide-tab-already:hover{background-color:#49ab3f}
        .lap-table,.lap-table-already{background-color:#8892BF;color:#fff;}
        .lap-table:hover,.lap-table-already:hover{background-color:#4f5b93}
        .unset-config{background-color:#0c0;color:#fff;}
        .unset-config:hover{background-color:#0a8;}
        .connect-info{background-color:#eee;color:#292929}
        .connect-info:hover{background-color:#ccc;}
        #connect_info:hover .connect-info-block{display:block;}
        .connect-info-block{position:absolute;right:0;font-size:13px;background-color:#eee;padding-top:6px;display:none;}
        .connect-info-block p{padding:6px 16px;margin:0;}
        .connect-info-block p .config-field{display:inline-block;width:58px;text-align:right;}
        .connect-info-block p .config-value{display:inline-block;color:#2a28d2;}
        .connect-info-block p:hover{background-color:#ccc;}
        .list-content{width:100%;margin:0 auto;padding:20px 0;}
        .table-name-title-block{padding:10px 0;}
        .table-name-title-block .table-name-title{margin:0;background-color:#f8f8f8;padding:0 4px;cursor:pointer;}
        .table-name-title-block .table-name-title.lap-off{border-bottom:1px solid #ddd;}
        .table-name-title-block .table-name-title .lap-icon{padding:0 10px;}
        .table-name-title-block .table-name-title .table-name-anchor{display:block;padding:10px 0;}
        .ul-sort-title{margin:0 0 -1px;padding:0;font-size:0;z-index:3;}
        ul.ul-sort-title,ul.ul-sort-title li{list-style:none;}
        .ul-sort-title li{display:inline-block;background:#fff;padding:10px 20px;border:1px solid #ddd;border-right:0;color:#333;cursor:pointer;font-size:13px;}
        .ul-sort-title li.active{background:#f0f0f0;border-bottom-color:#f0f0f0;}
        .ul-sort-title li:hover{background:#1588d9;border:1px solid #aaa;color:#fff;}
        .ul-sort-title li:last-child{border-right:1px solid #ddd;}
        .table-list{_width:2000px;margin:0 auto;}
        table{border-collapse:collapse;}
        table caption{text-align:left;background-color:LightGreen;line-height:2em;font-size:14px;font-weight:bold;border:1px solid #985454;padding:10px;}
        table th{text-align:left;font-weight:bold;height:26px;line-height:25px;font-size:13px;border:1px solid #ddd;background:#f0f0f0;padding:5px;}
        table td{height:25px;font-size:12px;border:1px solid #ddd;padding:5px;word-break:break-all;color:#333;}
        .db-table-name{padding:0 6px;}
        .column-index{width:40px;}
        .column-field{width:200px;}
        .column-data-type{width:130px;}
        .column-comment{width:310px;}
        .column-can-be-null{width:68px;}
        .column-auto-increment{width:68px;}
        .column-primary-key{width:40px;}
        .column-default-value{width:54px;}
        .column-character-set-name{width:54px;}
        .column-collation-name{width:100px;}
        .fix-category{position:fixed;width:300px;height:100%;overflow:auto;top:0;left:0;background:rgba(241,247,253,0.86);box-shadow:3px 0 6px rgba(0,0,0,.2);-webkit-box-shadow:3px 0 6px rgba(0,0,0,.2);-moz-box-shadow:3px 0 6px rgba(0,0,0,.2);z-index:99;}
        .fix-category:hover{z-index:101;}
        .fix-category-hide{left:-300px;overflow:hidden;background-color:rgba(0,23,255,0.22);cursor:pointer;}
        .fix-category ul{padding:5px;margin:0;}
        .fix-category ul li{margin:0;}
        .fix-category ul li:hover{background:darkseagreen;}
        .fix-category ul li a{display:block;padding: 5px 0 5px 8px;color:#1a407b;text-decoration:none;word-break:break-all;}
        .fix-category ul li:hover a,
        .fix-category ul li a:hover{color:#fff;}
        .fix-category ul li .category-table-name{display:none;padding: 5px 0 5px 22px;color:#1a407b;text-decoration:none;word-break:break-all;font-size:13px;}
        .fix-category ul li:hover .category-table-name{display:block;color:#fff;}
        .fix-category-handle-bar-off .lap-ul{left:0}
        .lap-ul{display:inline-block;width:12px;height:35px;background:rgba(12,137,42,0.43);border-bottom-right-radius:5px;border-top-right-radius:5px;position:fixed;top:50%;left:300px;cursor:pointer;border:1px solid rgba(31,199,58,0.43);font-size:12px;font-weight:normal;line-height:35px;text-align:center;}
        .fix-category::-webkit-scrollbar-track{-webkit-box-shadow:inset 0 0 6px rgba(0,0,0,0.3);-webkit-border-radius:10px;border-radius:10px}
        .fix-category::-webkit-scrollbar{width:6px;height:5px}
        .fix-category::-webkit-scrollbar-thumb{-webkit-border-radius:10px;border-radius:10px;background:rgba(231,178,13,0.31);-webkit-box-shadow:inset 0 0 6px rgba(231,178,13,0.31)}
        /* 错误页面 */
        .error-block{width:1000px;}
        .error-title-block{padding:20px 0}
        .error-title{text-align:center}
        .error-content-block{width:680px;margin:0 auto;padding:20px;background:#fff;border:1px solid #cfcfcf}
        .content-row{padding:15px 0}
        .content-row p{margin:0;}
        .content-row .content-normal-p{text-indent:2em;line-height:30px;}
        .text-center{text-align:center;}
        .reason-p{font-size:14px;padding:16px 0;line-height:40px;text-indent:4em;color:#f08080;}
        /* 配置数据库相关 */
        .data-setup-title{padding:20px 0}
        .setup-title{text-align:center}
        .data-form-block{width:680px;margin:0 auto;padding:20px;background:#fff;border:1px solid #cfcfcf}
        .input-row{padding:15px 10px;vertical-align:middle;line-height:22px}
        input{background-color:#fff;border:1px solid #ccc;-webkit-box-shadow:inset 0 1px 1px rgba(0,0,0,0.075);-moz-box-shadow:inset 0 1px 1px rgba(0,0,0,0.075);box-shadow:inset 0 1px 1px rgba(0,0,0,0.075);-webkit-transition:border linear .2s,box-shadow linear .2s;-moz-transition:border linear .2s,box-shadow linear .2s;-o-transition:border linear .2s,box-shadow linear .2s;transition:border linear .2s,box-shadow linear .2s;display:inline-block;padding:4px 6px;font-size:14px;line-height:20px;color:#555;vertical-align:middle;-webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px}
        input:focus{border-color:rgba(82,168,236,0.8);outline:0;outline:thin dotted \9;-webkit-box-shadow:inset 0 1px 1px rgba(0,0,0,0.075),0 0 8px rgba(82,168,236,0.6);-moz-box-shadow:inset 0 1px 1px rgba(0,0,0,0.075),0 0 8px rgba(82,168,236,0.6);box-shadow:inset 0 1px 1px rgba(0,0,0,0.075),0 0 8px rgba(82,168,236,0.6)}
        .input-field{display:inline-block;width:320px}
        .input-field label{display:inline-block;width:100px;text-align:right;vertical-align:middle}
        .normal-input{line-height:25px}
        .input-tips{display:inline-block;width:280px;padding-left:20px;vertical-align:middle}
        .form-handle{padding:20px;text-align:center}
        .btn{display:inline-block;text-align:center;vertical-align:middle;padding:10px 12px;text-decoration:none;margin:8px;font-size:14px;}
        .btn-tight{margin:0;}
        .setup-submit{width:100px;height:50px;background:#0059F7;color:#fff;border-radius:5px}
        .setup-submit:hover{background-color:#f72614}
        .setup-cancel{width:100px;height:50px;line-height:50px;background-color:#5cb85c;border-radius:5px;color:#fff;padding:0;}
        .setup-cancel:hover{background-color:#4fa94f}
        input[type="submit"],input[type="reset"]{border:none;cursor:pointer;-webkit-appearance:button}
        input[type="checkbox"]{margin-right:10px;cursor:pointer;}
        label.label-checkbox{width:auto;padding-left:100px;cursor:pointer}
        .data-form-block .tips{width:85%;margin:0 auto;}
        .data-form-block .tips .tips-p{padding:10px 14px;color:#555;font-size:13px;}
        .data-form-block .tips .tips-p.notice-important{background-color:#ffefef;border:1px solid #ffd2d2}
        /* 右下角 */
        .right-bar-block{position:fixed;left:50%;bottom:245px;margin-left:532px;}
        .right-bar-block .go-to-top{width:20px;border:1px solid #ddd;text-align:center;cursor:pointer;display:none;font-size:13px;padding:6px 0;}
    </style>
</head>
<body>
<div class="wrap">
    <!-- S 头部 S -->
    <div class="header">
    </div>
    <!-- E 头部 E-->
    <!-- S 主要内容 S -->
    <div class="main">
        <div class="main-content w-wrap">
            <% if ("config".equals(queryString)) {%>
            <div class="data-setup-title">
                <h1 class="setup-title">数据库配置</h1>
            </div>
            <div class="data-form-block">
                <div class="input-row">
                    <div class="input-field">
                        <label for="db_database">数据库名</label>
                        <input type="text" name="dbDatabase" id="db_database" value="<% out.print(tmpConfig.get("dbDatabase")!=null?tmpConfig.get("dbDatabase"):"heanes.com"); %>" class="normal-input" title="请输入数据库名" placeholder="请输入数据库名" required />
                    </div>
                    <div class="input-tips">
                        <span class="tips">将连接哪个数据库？</span>
                    </div>
                </div>
                <div class="input-row">
                    <div class="input-field">
                        <label for="db_user">用户名</label>
                        <!-- 解决浏览器自动填充数据的问题 -->
                        <label for="fake_db_user" style="display:none"></label>
                        <input type="text" name="fake_username_remembered" id="fake_db_user" style="display:none" />
                        <input type="text" name="dbUser" id="db_user" value="<% out.print(tmpConfig.get("dbUser")!=null?tmpConfig.get("dbUser"):"webdb");%>" class="normal-input" title="请输入用户名" placeholder="请输入用户名" required />
                    </div>
                    <div class="input-tips">
                        <span class="tips">你的MySQL用户名</span>
                    </div>
                </div>
                <div class="input-row">
                    <div class="input-field">
                        <label for="db_password">密码</label>
                        <!-- 解决浏览器自动填充数据的问题 -->
                        <label for="fake_db_password" style="display:none"></label>
                        <input type="password" name="fake_password_remembered" id="fake_db_password" style="display:none" />
                        <input type="password" name="dbPassword" id="db_password" autocomplete="off" value="<% out.print(tmpConfig.get("dbPassword")!=null?tmpConfig.get("dbPassword"):"p()P]aHqCEfwVY@7");%>" class="normal-input" title="请输入密码" placeholder="请输入密码" required />
                    </div>
                    <div class="input-tips">
                        <span class="tips">数据库密码</span>
                    </div>
                </div>
                <div class="input-row">
                    <div class="input-field">
                        <label for="db_server">数据库主机</label>
                        <input type="text" name="dbServer" id="db_server" value="<% out.print(tmpConfig.get("dbServer")!=null?tmpConfig.get("dbServer"):"localhost");%>" class="normal-input" title="请输入数据库主机" placeholder="localhost" required />
                    </div>
                    <div class="input-tips">
                        <span class="tips">连接地址，如localhost、IP地址</span>
                    </div>
                </div>
                <div class="input-row">
                    <div class="input-field">
                        <label for="db_port">端口</label>
                        <input type="text" name="dbPort" id="db_port" value="<% out.print(tmpConfig.get("dbPort")!=null?tmpConfig.get("dbPort"):"3306");%>" class="normal-input" title="请输入端口" placeholder="请输入端口" required />
                    </div>
                    <div class="input-tips">
                        <span class="tips">数据库连接什么端口？</span>
                    </div>
                </div>
                <div class="input-row">
                    <div class="input-field">
                        <label for="remember_config" class="label-checkbox"><input type="checkbox" name="rememberConfig" checked id="remember_config" value="1" />记住配置（存入Cookie）</label>
                    </div>
                </div>
                <div class="form-handle">
                    <div class="form-handle-field">
                        <span class="handle-cell"><input type="submit" class="btn setup-submit" name="setup_form_submit" id="db_set_submit" value="提交" /></span>
                        <span class="handle-cell"><a class="btn setup-cancel" href="javascript:history.back();">返回</a></span>
                    </div>
                </div>
            </div>
            <script type="text/javascript">
                var $db_set_submit = document.getElementById('db_set_submit');
                $db_set_submit.onclick = function (){
                    var $db_database = document.getElementById('db_database').value,
                            $db_user = document.getElementById('db_user').value,
                            $db_password = document.getElementById('db_password').value,
                            $db_server = document.getElementById('db_server').value,
                            $db_port = document.getElementById('db_port').value,
                            $remember_config = document.getElementById('remember_config');
                    var $remember_config_val = $remember_config.checked ? $remember_config.value : 0;
                    $.ajax({
                        url: "<%=baseUrl%>?postConfig",//请求地址
                        type: "POST",//请求方式
                        data: { db_server:$db_server, db_database: $db_database, db_user: $db_user, db_password: $db_password, db_port:$db_port ,remember_config:$remember_config_val},//请求参数
                        dataType: "json",
                        success: function (response, xml) {
                            // 此处放成功后执行的代码
                            window.location.href = "<%=baseUrl%>";
                        },
                        fail: function (status) {
                            // 此处放失败后执行的代码
                            alert('出现问题：' + status);
                        }
                    });
                };
            </script>
            <% }else if(tableMap != null && tableMap.size()>0){%>
            <div class="toolbar-block fixed" id="tool_bar">
                <div class="operate-db-block w-wrap">
                    <div class="handle-block">
                        <div class="toolbar-input-block search-input">
                            <label for="search_input" class="toolbar-input-label">输入表名检索：</label>
                            <input type="text" name="search_input" id="search_input" class="toolbar-input" placeholder="filter">
                            <span id="search_result_summary" class="search-result-summary">共<%=tableMap.size()%>个表</span>
                        </div>
                    </div>
                    <div class="absolute-block">
                        <div class="toolbar-button-block">
                            <a href="javascript:void(0);" class="btn btn-tight unset-config" id="unset_config">安全删除配置信息</a>
                        </div>
                        <div class="toolbar-button-block">
                            <a href="javascript:void(0);" class="btn btn-tight lap-table" id="lap_table">折叠内容</a>
                        </div>
                        <div class="toolbar-button-block">
                            <a href="javascript:void(0);" class="btn btn-tight hide-tab" id="hide_tab">隐藏排序tab</a>
                        </div>
                        <div class="toolbar-button-block">
                            <a href="?config" class="btn btn-tight change-db">切换数据库</a>
                        </div>
                        <div class="toolbar-button-block" id="connect_info">
                            <a href="javascript:void(0);" class="btn btn-tight connect-info">连接信息</a>
                            <div class="connect-info-block">
                                <p><span class="config-field">数据库：</span><span class="config-value"><% out.print(tmpConfig.get("dbDatabase")!=null?tmpConfig.get("dbDatabase"):"");%></span></p>
                                <p><span class="config-field">用户：</span><span class="config-value"><% out.print(tmpConfig.get("dbUser")!=null?tmpConfig.get("dbUser"):"");%></span></p>
                                <p><span class="config-field">主机：</span><span class="config-value"><% out.print(tmpConfig.get("dbServer")!=null?tmpConfig.get("dbServer"):"");%></span></p>
                                <p><span class="config-field">端口：</span><span class="config-value"><% out.print(tmpConfig.get("dbPort")!=null?tmpConfig.get("dbPort"):"");%></span></p>
                                <p><span class="config-field">表总数：</span><span class="config-value"><%=tableMap.size()%></span></p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="toolbar-block-placeholder"></div>
            <div class="fix-category" id="fix_category">
                <div class="category-content-block">
                    <ul>
                        <%int j = 1;for(String tableName : tableMap.keySet()){%>
                        <li>
                            <a href="#<%=tableName%>"><%=String.format("%0"+(tableMap.size() + "").length() + "d", j) + "." + tableName%><span class="category-table-name"><%=tableMap.get(tableName).get(0).tableComment%></span></a>
                        </li>
                        <% j++;}%>
                    </ul>
                </div>
            </div>
            <div class="fix-category-handle-bar">
                <b class="lap-ul" id="lap_ul"><</b>
            </div>
            <div class="list-content">
                <h2 style="text-align:center;"><%=title%></h2>
                <div class="table-list" id="table_list">
                    <%j = 1;for(String tableName : tableMap.keySet()) {%>
                    <div class="table-one-block">
                        <div class="table-name-title-block">
                            <h3 class="table-name-title lap-on">
                                <a id="<%=tableName%>" class="table-name-anchor">
                                    <span class="lap-icon">-</span>
                                    <span class="db-table-index"><%=String.format("%0"+(tableMap.size() + "").length() + "d", j)%>.</span>
                                    <span class="db-table-name"><%=tableName%></span>
                                    <span class="db-table-comment"><%=tableMap.get(tableName).get(0).tableComment%></span>
                                </a>
                            </h3>
                        </div>
                        <div class="table-one-content">
                            <ul class="ul-sort-title">
                                <li class="active"><span>自然结构</span></li>
                                <li><span>字段排序</span></li>
                            </ul>
                            <table>
                                <thead>
                                <tr>
                                    <th>序号</th><th>字段名</th><th>数据类型</th><th>注释</th><th>允许空值</th><th>默认值</th><th>自动递增</th><th>主键</th><th>字符集</th><th>排序规则</th>
                                </tr>
                                </thead>
                                <tbody>
                                <%for(int k = 0, size = tableMap.get(tableName).size();k<size;k++){%>
                                <tr>
                                    <td class="column-index"><%=String.format("%0"+ (size+"").length() + "d", k+1)%></td>
                                    <td class="column-field"><%=tableMap.get(tableName).get(k).columnName%></td>
                                    <td class="column-data-type"><%=tableMap.get(tableName).get(k).columnType%></td>
                                    <td class="column-comment"><%=tableMap.get(tableName).get(k).columnComment%></td>
                                    <td class="column-can-be-null"><%=tableMap.get(tableName).get(k).isNullable%></td>
                                    <td class="column-default-value"><%=tableMap.get(tableName).get(k).columnDefault%></td>
                                    <td class="column-auto-increment"><%=("auto_increment".equals(tableMap.get(tableName).get(k).extra) ? "YES" : "")%></td>
                                    <td class="column-primary-key"><%=("PRI".equals(tableMap.get(tableName).get(k).columnKey) ? "YES" : "")%></td>
                                    <td class="column-character-set-name"><%=tableMap.get(tableName).get(k).characterSetName%></td>
                                    <td class="column-collation-name"><%=tableMap.get(tableName).get(k).collationName%></td>
                                </tr>
                                <% }%>
                                </tbody>
                            </table>
                            <table style="display:none;">
                                <thead>
                                <tr>
                                    <th>序号</th><th>字段名</th><th>数据类型</th><th>注释</th><th>允许空值</th><th>默认值</th><th>自动递增</th><th>主键</th><th>字符集</th><th>排序规则</th>
                                </tr>
                                </thead>
                                <tbody>
                                <%for(int k = 0, size = tableSortedMap.get(tableName).size();k<size;k++){%>
                                <tr>
                                    <td class="column-index"><%=String.format("%0"+ (size+"").length() + "d", k+1)%></td>
                                    <td class="column-field"><%=tableSortedMap.get(tableName).get(k).columnName%></td>
                                    <td class="column-data-type"><%=tableSortedMap.get(tableName).get(k).columnType%></td>
                                    <td class="column-comment"><%=tableSortedMap.get(tableName).get(k).columnComment%></td>
                                    <td class="column-can-be-null"><%=tableSortedMap.get(tableName).get(k).isNullable%></td>
                                    <td class="column-default-value"><%=tableSortedMap.get(tableName).get(k).columnDefault%></td>
                                    <td class="column-auto-increment"><%=("auto_increment".equals(tableSortedMap.get(tableName).get(k).extra) ? "YES" : "")%></td>
                                    <td class="column-primary-key"><%=("PRI".equals(tableSortedMap.get(tableName).get(k).columnKey) ? "YES" : "")%></td>
                                    <td class="column-character-set-name"><%=tableSortedMap.get(tableName).get(k).characterSetName%></td>
                                    <td class="column-collation-name"><%=tableSortedMap.get(tableName).get(k).collationName%></td>
                                </tr>
                                <% }%>
                                </tbody>
                            </table>
                        </div>
                    </div>
                    <% j++;}%>
                </div>
            </div>
            <div class="right-bar-block">
                <div class="right-bar-nav">
                    <div class="go-to-top" id="go_to_top">回顶部</div>
                </div>
            </div>
            <script type="text/javascript">
                // 键入字符检索表
                var $table_list_arr = [];
                <% int i=0;for(String tableName : tableMap.keySet()) {%>
                    $table_list_arr[<%=i%>] = "<%=tableName%>";
                <% i++;}%>
                var $search_input = document.getElementById('search_input');
                $search_input.onkeyup = function(){
                    var $pattern = $search_input.value;
                    var $lap_table = document.getElementById('lap_table');
                    var table_list = document.getElementById('table_list');
                    var $fix_category = document.getElementById('fix_category');
                    var $category_ul = $fix_category.getElementsByTagName('ul');
                    var $category_li_list = $category_ul[0].children;
                    var $match_result = [];
                    for (var i = 0, $table_count = $table_list_arr.length; i < $table_count; i++){
                        if($table_list_arr[i].match($pattern)){
                            $match_result.push(i);
                            table_list.children[i].style.display = 'block';
                            table_list.children[i].children[0].className = 'table-name-title-block lap-off';
                            table_list.children[i].children[0].children[0].className = 'table-name-title lap-off';
                            table_list.children[i].children[1].style.display = 'none';
                            table_list.children[i].children[0].children[0].children[0].children[0].innerText = "+";
                            // 高亮样式
                            table_list.children[i].children[0].children[0].children[0].children[2].innerHTML =
                                    table_list.children[i].children[0].children[0].children[0].children[2].innerText;
                            table_list.children[i].children[0].children[0].children[0].children[2].innerHTML =
                                    table_list.children[i].children[0].children[0].children[0].children[2].innerHTML.replace($pattern, '<strong style="color:red;">'+ $pattern +'</strong>');
                            $category_li_list[i].children[0].style.color = '#c71212';
                        }else{
                            table_list.children[i].style.display = 'none';
                            table_list.children[i].children[0].className = 'table-name-title-block lap-on';
                            table_list.children[i].children[0].children[0].className = 'table-name-title lap-on';
                            table_list.children[i].children[1].style.display = 'block';
                            table_list.children[i].children[0].children[0].children[0].children[2].innerHTML =
                                    table_list.children[i].children[0].children[0].children[0].children[2].innerText;
                            $category_li_list[i].children[0].style.color = '';
                        }
                    }
                    var $search_result_summary = document.getElementById('search_result_summary');
                    $search_result_summary.innerText = '共' + $match_result.length + '条结果';
                    // 若只有一条匹配记录，则展开显示
                    if($match_result.length == 1){
                        table_list.children[$match_result[0]].children[0].className = 'table-name-title-block lap-on';
                        table_list.children[$match_result[0]].children[1].style.display = 'block';
                        table_list.children[$match_result[0]].children[0].children[0].children[0].children[0].innerText = "-";
                        $lap_table.className = 'btn btn-tight lap-table';
                        $lap_table.innerHTML = '折叠内容';
                    }else{
                        $lap_table.className = 'btn btn-tight lap-table-already';
                        $lap_table.innerHTML = '展开内容';
                        if($match_result.length == $table_list_arr.length){
                            $search_result_summary.innerText = '共' + $table_list_arr.length + '个表';
                            for(var j = 0; j<$match_result.length; j++){
                                $category_li_list[j].children[0].style.color = '';
                            }
                        }
                    }
                };
                //点击隐藏侧边导航栏
                var $fixLap = document.getElementById('lap_ul');
                $fixLap.onclick = function(){
                    var fixCategory = document.getElementById('fix_category');
                    var fixCategoryHandleBar = this.parentNode;
                    if(fixCategoryHandleBar.className == 'fix-category-handle-bar'){
                        fixCategory.className = 'fix-category fix-category-hide';
                        fixCategoryHandleBar.className = 'fix-category-handle-bar fix-category-handle-bar-off';
                        this.innerHTML='>';
                    }else if(fixCategoryHandleBar.className == 'fix-category-handle-bar fix-category-handle-bar-off'){
                        fixCategory.className = 'fix-category';
                        fixCategoryHandleBar.className = 'fix-category-handle-bar';
                        this.innerHTML='<';
                    }
                };
                var $fix_category = document.getElementById('fix_category');
                $fix_category.onclick = function () {
                    var $toolBar = document.getElementById('tool_bar');
                    $toolBar.style.position = 'absolute';
                };
                var table_list = document.getElementById('table_list');
                // 内容折叠
                var $title_arr = table_list.getElementsByTagName('h3');
                for (i = 0, $title_arr_length = $title_arr.length; i < $title_arr_length; i++){
                    $title_arr[i].onclick = function(){
                        this.parentNode.nextElementSibling.style.display = (this.parentNode.nextElementSibling.style.display === "none" ? "block" : "none");
                        this.className = (this.className == "table-name-title lap-off" ? "table-name-title lap-on" : "table-name-title lap-off");
                        this.parentNode.className = (this.parentNode.className == "table-name-title-block lap-off" ? "table-name-title-block lap-on" : "table-name-title-block lap-off");
                        this.children[0].children[0].innerText = (this.className == "table-name-title lap-on" ? '-' : '+');
                    }
                }
                // 折叠/展开所有
                var $lap_table = document.getElementById('lap_table');
                $lap_table.onclick = function(){
                    var i = 0,$title_arr_length = 0;
                    if(this.className == 'btn btn-tight lap-table'){
                        for (i = 0, $title_arr_length = $title_arr.length; i < $title_arr_length; i++){
                            $title_arr[i].className = 'table-name-title lap-off';
                            $title_arr[i].parentNode.nextElementSibling.style.display = 'none';
                            $title_arr[i].children[0].children[0].innerText = '+';
                        }
                        this.className = 'btn btn-tight lap-table-already';
                        this.innerHTML = '展开内容';
                        return true;
                    }
                    if(this.className == 'btn btn-tight lap-table-already'){
                        for (i = 0, $title_arr_length = $title_arr.length; i < $title_arr_length; i++){
                            $title_arr[i].className = 'table-name-title lap-on';
                            $title_arr[i].parentNode.nextElementSibling.style.display = 'block';
                            $title_arr[i].children[0].children[0].innerText = '-';
                        }
                        this.className = 'btn btn-tight lap-table';
                        this.innerHTML = '折叠内容';
                        return true;
                    }
                };
                // Tab切换
                var ul_arr = table_list.getElementsByTagName('ul');
                for (i = 0, ul_arr_length = ul_arr.length; i < ul_arr_length; i++) {
                    var li_arr = ul_arr[i].getElementsByTagName('li');
                    for(var j = 0;j<li_arr.length;j++){
                        (function(j){
                            li_arr[j].onclick = function() {
                                var ul = this.parentNode;
                                //标题样式切换
                                var li = ul.getElementsByTagName('li');
                                for (var k = 0; k < li.length; k++) {
                                    li[k].className = '';
                                }
                                this.className = 'active';
                                var div = ul.parentNode;
                                //表格切换显示
                                var tables = div.getElementsByTagName('table');
                                for (var l = 0; l < tables.length; l++) {
                                    tables[l].style.display = 'none';
                                }
                                tables[j].style.display = 'block';
                            }
                        }(j));
                    }
                }
                //隐藏Tab
                var $hide_tab = document.getElementById('hide_tab');
                $hide_tab.onclick = function(){
                    var i = 0, ul_arr_length = 0;
                    if(this.className == 'btn btn-tight hide-tab-already'){
                        for (i = 0, ul_arr_length = ul_arr.length; i < ul_arr_length; i++) {
                            ul_arr[i].style.display = 'block';
                        }
                        this.className = 'btn btn-tight hide-tab';
                        this.innerHTML = '隐藏排序tab';
                        return true;
                    }
                    if(this.className == 'btn btn-tight hide-tab'){
                        for (i = 0, ul_arr_length = ul_arr.length; i < ul_arr_length; i++) {
                            ul_arr[i].style.display = 'none';
                        }
                        this.className = 'btn btn-tight hide-tab-already';
                        this.innerHTML = '显示排序tab';
                        return true;
                    }
                };
                //删除配置信息
                var $unset_config = document.getElementById('unset_config');
                $unset_config.onclick = function () {
                    if (!confirm('确认删除吗？')){
                        return false;
                    }
                    $.ajax({
                        url: "<%=baseUrl%>?unsetConfig",//请求地址
                        type: "POST",                                           //请求方式
                        dataType: "json",
                        success: function (response, xml) {
                            // 此处放成功后执行的代码
                            window.location.href = "<%=baseUrl%>?deleteSuccess";
                        },
                        fail: function (status) {
                            // 此处放失败后执行的代码
                            alert('出现问题：' + status);
                        }
                    });
                };
                //回到顶部功能
                goToTop('go_to_top', false);

                /**
                 * @doc 回到顶部功能函数
                 * @param id string DOM选择器ID
                 * @param show boolean true是一直显示按钮，false是当滚动距离超过指定高度时显示按钮
                 * @param height integer 超过高度才显示按钮
                 * @author fanggang
                 * @time 2015-11-19 15:44:51
                 */
                function goToTop (id, show, height) {
                    var oTop = document.getElementById(id);
                    oTop.onclick = scrollToTop;

                    function scrollToTop() {
                        var d = document,
                                dd = document.documentElement,
                                db = document.body,
                                top = dd.scrollTop || db.scrollTop,
                                step = Math.floor(top / 20);
                        (function() {
                            top -= step;
                            if (top > -step) {
                                dd.scrollTop == 0 ? db.scrollTop = top: dd.scrollTop = top;
                                setTimeout(arguments.callee, 20);
                            }
                        })();
                    }
                }
            </script>
            <% }%>
            <% if ("mysqlConnectError".equals(queryString)) {%>
            <div class="error-block">
                <div class="error-title-block">
                    <h1 class="error-title">数据库连接错误</h1>
                </div>
                <div class="error-content-block">
                    <div class="content-row">
                        <p class="content-normal-p">数据库连接错误，请检查配置信息是否填写正确。</p>
                        <p class="content-p reason-p">
                            <% out.print(request.getAttribute("_db_connect_errno")!=null ? request.getAttribute("_db_connect_errno") : "Unknown error code"); %> :
                            <% out.print(request.getAttribute("_db_connect_error")!=null ? request.getAttribute("_db_connect_error") : "Unknown reason"); %>
                        </p>
                        <p class="text-center"><a href="?config" class="btn change-db">重新填写数据库配置</a></p>
                    </div>
                </div>
            </div>
            <% }%>
            <% if ("deleteSuccess".equals(queryString)) {%>
            <div class="error-block">
                <div class="error-title-block">
                    <h1 class="error-title">已经成功删除保存的配置信息</h1>
                </div>
                <div class="error-content-block">
                    <div class="content-row">
                        <p class="content-normal-p">已经成功删除保存的配置信息：Session与Cookie中的配置信息均已被安全删除。</p>
                        <p class="text-center"><a href="?config" class="btn change-db">重新填写数据库配置</a></p>
                    </div>
                </div>
            </div>
            <% }%>
        </div>
    </div>
    <!-- E 主要内容 E -->
    <div class="clear"></div>
    <!-- S 脚部 S -->
    <div class="footer"></div>
    <!-- E 脚部 E -->
    <script type="text/javascript">
        var $ = {};
        $.ajax = function ajax(options) {
            options = options || {};
            options.type = (options.type || "GET").toUpperCase();
            options.dataType = options.dataType || "json";
            var params = formatParams(options.data);

            //创建 - 非IE6 - 第一步
            /*if (window.XMLHttpRequest) {
             var xhr = new XMLHttpRequest();
             } else { //IE6及其以下版本浏览器
             var xhr = new ActiveXObject('Microsoft.XMLHTTP');
             }*/

            var xhr = createAjax();

            //接收 - 第三步
            xhr.onreadystatechange = function () {
                if (xhr.readyState == 4) {
                    var status = xhr.status;
                    if (status >= 200 && status < 300) {
                        options.success && options.success(xhr.responseText, xhr.responseXML);
                    } else {
                        options.fail && options.fail(status);
                    }
                }
            };

            //连接 和 发送 - 第二步
            if (options.type == "GET") {
                xhr.open("GET", options.url + "?" + params, true);
                xhr.send(null);
            } else if (options.type == "POST") {
                xhr.open("POST", options.url, true);
                //设置表单提交时的内容类型
                xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                xhr.send(params);
            }
        };
        //格式化参数
        function formatParams(data) {
            var arr = [];
            for (var name in data) {
                if (data.hasOwnProperty(name)) {
                    arr.push(encodeURIComponent(name) + "=" + encodeURIComponent(data[name]));
                }
            }
            return arr.join("&");
        }

        var createAjax = function() {
            var xhr = null;
            try {
                //IE系列浏览器
                xhr = new ActiveXObject("microsoft.xmlhttp");
            } catch (e1) {
                try {
                    //非IE浏览器
                    xhr = new XMLHttpRequest();
                } catch (e2) {
                    window.alert("您的浏览器不支持ajax，请更换！");
                }
            }
            return xhr;
        };

        //浏览器滚动事件处理
        window.onscroll = function(e) {
            /**
             * 顶部导航当用户向下滚动时不钉住，向上滚动时钉住
             * @author 方刚
             * @time 2014-10-30 16:08:58
             */
            var scrollFunc = function(e) {
                e = e || window.event;
                var $toolBar = document.getElementById('tool_bar');
                if (e.wheelDelta) { // 判断浏览器IE，谷歌滑轮事件
                    if (e.wheelDelta > 0) { // 当滑轮向上滚动时
                        //alert("滑轮向上滚动");
                        $toolBar.style.position = 'fixed';
                    }
                    if (e.wheelDelta < 0) { // 当滑轮向下滚动时
                        //alert("滑轮向下滚动");
                        $toolBar.style.position = 'absolute';
                    }
                } else if (e.detail) { // Firefox滑轮事件与Chrome刚好相反
                    if (e.detail > 0) { // 当滑轮向上滚动时
                        //alert("滑轮向下滚动");
                        $toolBar.style.position = 'absolute';
                    }
                    if (e.detail < 0) { // 当滑轮向下滚动时
                        //alert("滑轮向上滚动");
                        $toolBar.style.position = 'fixed';
                    }
                }
            };
            // 给页面绑定滑轮滚动事件
            if (document.addEventListener) {
                document.addEventListener('DOMMouseScroll', scrollFunc, false);
            }
            // 滚动滑轮触发scrollFunc方法
            window.onmousewheel = document.onmousewheel = scrollFunc;

            /**
             * 如果滚动幅度超过半屏浏览器则淡出“回到顶部按钮”
             * @author 方刚
             * @times
             */
            var $go_to_top = document.getElementById('go_to_top');
            var scrollTop = document.documentElement.scrollTop || document.body.scrollTop;
            if(scrollTop > (getWindowSize().height * 3 /4)){
                $go_to_top.style.display = 'block';
            }
            else{
                $go_to_top.style.display = 'none';
            }
        };
        /**
         * 获取窗口可视宽高
         * @author 方刚
         * @time 2014-10-28 17:51:55
         * @returns Array
         */
        function getWindowSize() {
            var winHeight, winWidth;
            if (document.documentElement && document.documentElement.clientHeight && document.documentElement.clientWidth) {
                winHeight = document.documentElement.clientHeight;
                winWidth = document.documentElement.clientWidth;
            }
            var seeSize = [];
            seeSize['width'] = winWidth;
            seeSize['height'] = winHeight;
            return seeSize;
        }
    </script>
</div>
</body>
</html>