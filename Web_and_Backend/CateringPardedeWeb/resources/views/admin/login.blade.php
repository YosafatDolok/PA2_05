<!DOCTYPE html>
<html>
<head>
    <title>Admin Login</title>

    <style>

        body{
            font-family: Arial;
            background:#f4f6f9;
            display:flex;
            justify-content:center;
            align-items:center;
            height:100vh;
        }

        .login-box{
            background:white;
            padding:30px;
            width:300px;
            border-radius:8px;
            box-shadow:0 2px 8px rgba(0,0,0,0.1);
        }

        input{
            width:100%;
            padding:10px;
            margin-top:10px;
        }

        button{
            width:100%;
            padding:10px;
            margin-top:15px;
            background:#3498db;
            color:white;
            border:none;
        }

    </style>
</head>

<body>

<div class="login-box">

<h2>Admin Login</h2>

@if(session('error'))
<p style="color:red">{{ session('error') }}</p>
@endif

<form method="POST" action="/login">

@csrf

<input type="email" name="email" placeholder="Email">

<input type="password" name="password" placeholder="Password">

<button type="submit">Login</button>

</form>

</div>

</body>
</html>