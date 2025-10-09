codeunit 50013 "SPN Perfion Image Helper"
{
    procedure DownloadImageAsStream(Url: Text; var InStr: InStream): Boolean
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
    begin
        if Url = '' then
            exit(false);

        if not Client.Get(Url, Response) then
            exit(false);

        if not Response.IsSuccessStatusCode then
            exit(false);

        Response.Content.ReadAs(InStr);
        exit(true);
    end;
}
