unit main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, system.JSON;

type
  TForm2 = class(TForm)
    EdtNome: TEdit;
    EdtEmail: TEdit;
    EdtPassword: TEdit;
    Edit4: TEdit;
    Nome: TLabel;
    Email: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Button1: TButton;
    EdtGrupos: TEdit;
    Label2: TLabel;
    Label1: TLabel;
    procedure rect_criar_contaClick(Sender: TObject);
  private

    function CreateAccount(email, senha: string; out idUsuario,
      erro: string): boolean;
    function InsertUserToDatabase(idUsuario, email, nomeUsuario, grupo,
      linkFotoPerfil: string; out erro: string): boolean;
    procedure InsertUserToGroups(idUsuario, grupos: string);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;


const
  api_firebase = 'AIzaSyBi-0KnIdhlzNh_RCkptBJbgKt2rDR475g'; //tá desatualizado mesmo, vou deixar publico

implementation

{$R *.fmx}

uses Firebase.Auth, Firebase.Database, Firebase.Interfaces, Firebase.Request,
  Firebase.Response;

procedure TForm2.rect_criar_contaClick(Sender: TObject);
var
    idUsuario, erro : string;
begin
    if NOT CreateAccount(EdtEmail.Text,
                          EdtPassword.Text,
                         idUsuario,
                         erro) then
        showmessage(erro)
    else
        showmessage('Conta criada com sucesso: ' + idUsuario);

end;

function TForm2.CreateAccount(email, senha: string;
                              out idUsuario, erro: string): boolean;
var
    fbAuth : IFirebaseAuth;
    resp : IFirebaseResponse;
    json, jsonRet : TJSONObject;
    jsonValue : TJSONValue;
    fotoTemp: String;
begin
    fotoTemp := 'https://firebasestorage.googleapis.com/v0/b/appviacriativa.appspot.com/o/Icon_250.jpg?alt=media&token=799ca102-9d61-48f6-b69f-36d0613085cb';
    try
        erro := '';
        fbAuth := TFirebaseAuth.Create;
        fbAuth.SetApiKey(api_firebase);
        resp := fbAuth.CreateUserWithEmailAndPassword(email, senha);
        try
            json := TJSONObject.ParseJSONValue(
                            TEncoding.UTF8.GetBytes(resp.ContentAsString), 0) as TJSONObject;
            if NOT Assigned(json) then
            begin
                Result := false;
                erro := 'Não foi possível verificar o retorno do servidor (JSON inválido)';
                exit;
            end;
        except on ex:exception do
            begin
                Result := false;
                erro := ex.Message;
                exit;
            end;
        end;
        if json.TryGetValue('error', jsonRet) then
        begin
            erro := jsonRet.Values['message'].Value;
            Result := false;
        end
        else if json.TryGetValue('localId', jsonValue) then
        begin
            idUsuario := jsonValue.Value;
            // Inserir usuário no banco de dados
            if not InsertUserToDatabase(idUsuario, EdtEmail.Text, EdtNome.Text,EdtGrupos.Text,fotoTemp, erro) then
            begin
                Result := false;
                exit;
            end;
            Result := true;
        end
        else
        begin
            erro := 'Retorno desconhecido';
            Result := false;
        end;
    finally
        if Assigned(json) then
            json.DisposeOf;
    end;
end;

function TForm2.InsertUserToDatabase(idUsuario, email, nomeUsuario, grupo, linkFotoPerfil: string; out erro: string): boolean;
var
  FirebaseDB: TFirebaseDatabase;
  Response: IFirebaseResponse;
  UserJson: TJSONObject;
begin
  Result := false;
  UserJson := TJSONObject.Create;
  try
    UserJson.AddPair('EMAIL', email);
    UserJson.AddPair('NOMEUSUARIO', nomeUsuario);
    UserJson.AddPair('LINKFOTOPERFIL', linkFotoPerfil);
    UserJson.AddPair('GRUPOS', grupo);
    UserJson.AddPair('XP', TJSONNumber.Create(0));
    UserJson.AddPair('STATUSONLINE', TJSONBool.Create(False));
    FirebaseDB := TFirebaseDatabase.Create;
    try
      FirebaseDB.BaseURI := 'https://appviacriativa-default-rtdb.firebaseio.com';
      FirebaseDB.Token := 'OYWhR4sdLoJDbG9bPQrf7MiebYbhF3zjzzCTBqOw';

      Response := FirebaseDB.Put(['USERS', idUsuario + '.json'], UserJson);
      if Response.IsSuccess then
      begin
        Result := true;
        ShowMessage('Inserção feita com sucesso!');
      end
      else
      begin
        erro := Response.ContentAsString;
        ShowMessage('Falha de inserção: ' + erro);
      end;
    finally
      FirebaseDB.Free;
    end;
  finally
    InsertUserToGroups(idUsuario, grupo);
    //UserJson.Free;
    //nao entendo pq isso está dando erro de memoria
  end;
end;

{Procedure TForm2.InsertUserToGroups(idUsuario, grupos: string);
var
  FirebaseDB: TFirebaseDatabase;
  GroupsJson: TJSONObject;
  GroupList: TStringList;
  GroupName: string;
begin
  // Criando instância do Firebase Database e definindo as credenciais
  FirebaseDB := TFirebaseDatabase.Create;
  try
    FirebaseDB.BaseURI := 'https://appviacriativa-default-rtdb.firebaseio.com';
    FirebaseDB.Token := 'OYWhR4sdLoJDbG9bPQrf7MiebYbhF3zjzzCTBqOw'; // Se necessário
    // Criando um objeto JSON para os grupos
    GroupsJson := TJSONObject.Create;
    // Separando a string de grupos em que o usuário está cadastrado
    GroupList := TStringList.Create;
    try
      GroupList.Delimiter := ';'; // Usar ponto e vírgula como separador
      GroupList.DelimitedText := grupos;
      // Iterando pelos grupos
      for GroupName in GroupList do
      begin
        // Criando um objeto JSON para o grupo, com o ID do usuário
        GroupsJson.AddPair(GroupName, TJSONArray.Create(TJSONString.Create(idUsuario)));
      end;
      // Atualizando o documento "GRUPOS" no Realtime Database
      FirebaseDB.Put(['GRUPOS.json'], GroupsJson);
    finally
      GroupList.Free;
    end;
  finally
    FirebaseDB.Free;
  end;
end;     }

{procedure TForm2.InsertUserToGroups(idUsuario, grupos: string);
var
  FirebaseDB: TFirebaseDatabase;
  GroupsJson: TJSONObject;
  GroupList: TStringList;
  GroupName: string;
begin
  // Criando instância do Firebase Database e definindo as credenciais
  FirebaseDB := TFirebaseDatabase.Create;
  try
    FirebaseDB.BaseURI := 'https://appviacriativa-default-rtdb.firebaseio.com';
    FirebaseDB.Token := 'OYWhR4sdLoJDbG9bPQrf7MiebYbhF3zjzzCTBqOw'; // Se necessário
    // Criando um objeto JSON para os grupos
    GroupsJson := TJSONObject.Create;
    // Separando a string de grupos em que o usuário está cadastrado
    GroupList := TStringList.Create;
    try
      GroupList.Delimiter := ';'; // Usar ponto e vírgula como separador
      GroupList.DelimitedText := grupos;
      // Iterando pelos grupos
      for GroupName in GroupList do
      begin
        // Verificando se o grupo já existe no documento "GRUPOS"
        if GroupsJson.GetValue(GroupName) <> nil then
        begin
          // Grupo já existe, adicionando o ID do usuário à lista de usuários
          TJSONArray(GroupsJson.GetValue(GroupName)).Add(idUsuario);
        end
        else
        begin
          // Grupo não existe, criando um novo grupo com o ID do usuário na lista de usuários
          GroupsJson.AddPair(GroupName, TJSONArray.Create(TJSONString.Create(idUsuario)));
        end;
      end;
      // Atualizando o documento "GRUPOS" no Realtime Database
      FirebaseDB.Patch(['GRUPOS.json'], GroupsJson);
    finally
      GroupList.Free;
    end;
  finally
    FirebaseDB.Free;
  end;
end;    }
//procedure TForm2.InsertUserToGroups(idUsuario, grupos: string);
//var
//  FirebaseDB: TFirebaseDatabase;
//  GroupList: TStringList;
//  GroupName: string;
//  UserGroupNode: TJSONObject;
//  UsersInGroup: TJSONObject;
//  ResponseContent: string;
//begin
//  FirebaseDB := TFirebaseDatabase.Create;
//  try
//    FirebaseDB.BaseURI := 'https://appviacriativa-default-rtdb.firebaseio.com';
//    FirebaseDB.Token := 'OYWhR4sdLoJDbG9bPQrf7MiebYbhF3zjzzCTBqOw';
//
//    GroupList := TStringList.Create;
//    try
//      GroupList.Delimiter := ';';
//      GroupList.DelimitedText := grupos;
//
//      for GroupName in GroupList do
//      begin
//        // Verificar se o grupo já existe em "GRUPOS"
//        ResponseContent := FirebaseDB.Get(['GRUPOS', GroupName + '.json']).ContentAsString;
//
//        if ResponseContent <> '' then
//        begin
//          UsersInGroup := TJSONObject.ParseJSONValue(ResponseContent) as TJSONObject;
//
//          if UsersInGroup = nil then
//          begin
//            // Se o grupo não existir, criar um objeto JSON para ele
//            UsersInGroup := TJSONObject.Create;
//          end;
//
//          // Criar um objeto JSON para o nó do usuário no grupo
//          UserGroupNode := TJSONObject.Create;
//          UserGroupNode.AddPair('USERID', TJSONString.Create(idUsuario));
//
//          // Adicionar o nó do usuário ao grupo
//          UsersInGroup.AddPair('USERS', UserGroupNode);
//
//          // Atualizar o documento "GRUPOS" com os usuários no grupo
//          FirebaseDB.Put(['GRUPOS', GroupName + '.json'], UsersInGroup);
//        end;
//      end;
//    finally
//      GroupList.Free;
//    end;
//  finally
//    FirebaseDB.Free;
//  end;
//end;
procedure TForm2.InsertUserToGroups(idUsuario, grupos: string);
var
  FirebaseDB: TFirebaseDatabase;
  GroupList: TStringList;
  GroupName: string;
  UsersInGroup: TJSONObject;
begin
  FirebaseDB := TFirebaseDatabase.Create;
  try
    FirebaseDB.BaseURI := 'https://appviacriativa-default-rtdb.firebaseio.com';
    FirebaseDB.Token := 'OYWhR4sdLoJDbG9bPQrf7MiebYbhF3zjzzCTBqOw';
    GroupList := TStringList.Create;
    try
      GroupList.Delimiter := ';';
      GroupList.DelimitedText := grupos;
      for GroupName in GroupList do
      begin
        UsersInGroup := TJSONObject.Create;
        UsersInGroup.AddPair(idUsuario, TJSONString.Create(idUsuario));
        FirebaseDB.Patch(['GRUPOS', GroupName, 'USERS.json'], UsersInGroup);
      end;
    finally
      GroupList.Free;
    end;
  finally
    FirebaseDB.Free;
  end;
end;




end.
