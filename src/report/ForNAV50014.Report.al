#pragma warning disable AA0005, AA0008, AA0018, AA0021, AA0072, AA0137, AA0201, AA0204, AA0206, AA0218, AA0228, AL0254, AL0424, AS0011, AW0006 // ForNAV settings
dotnet // --> Reports ForNAV Autogenerated code - do not delete or modify
{
    assembly("ForNav.Reports.7.2.0.2471")
    {
        type(ForNav.Report_7_2_0_2471; ForNavReport50014_v7_2_0_2471) { }
    }
    assembly("mscorlib")
    {
        Version = '4.0.0.0';
        type("System.IO.Stream"; SystemIOStream50014) { }
        type("System.IO.Path"; System_IO_Path50014) { }
    }
} // Reports ForNAV Autogenerated code - do not delete or modify -->















Report 50014 "ForNAV 50014"
{
    RDLCLayout = '.\Layouts\ForNAV50014.rdlc';
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Integer; Integer)
        {
            MaxIteration = 1;
            DataItemTableView = sorting(Number) where(Number = FILTER(1 ..));
            column(ReportForNavId_3; 3) { } // Autogenerated by ForNav - Do not delete
        }
        dataitem(Customer; Customer)
        {
            DataItemTableView = where("Country/Region Code" = FILTER(<> 'DK'));
            column(ReportForNavId_1; 1) { } // Autogenerated by ForNav - Do not delete
            dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
            {
                CalcFields = "Amount (LCY)";
                DataItemLink = "Customer No." = FIELD("No.");
                DataItemTableView = where(Open = CONST(true));
                column(ReportForNavId_2; 2) { } // Autogenerated by ForNav - Do not delete
                column(LineNo; LineNo)
                {
                    IncludeCaption = false;
                }
                column(StartingDate; StartingDate)
                {
                    IncludeCaption = false;
                }
                column(EndingDate; EndingDate)
                {
                    IncludeCaption = false;
                }
                trigger OnPreDataItem();
                begin
                    "Cust. Ledger Entry".SetRange("Posting Date", StartingDate, EndingDate);
                end;

                trigger OnAfterGetRecord();
                var
                    SetSKip: Boolean;
                begin
                    LineNo += 1;
                    SetSkip := false;
                    if CountryRegion.Get(Customer."Country/Region Code") then begin
                        SetSKip := false;
                        if CountryRegion."EU Country/Region Code" = '' then SetSKip := true;
                    end else
                        SetSkip := true;
                    if SetSKip = true then CurrReport.Skip();
                end;

            }
        }
        dataitem(Integer2; Integer)
        {
            MaxIteration = 1;
            DataItemTableView = sorting(Number) where(Number = FILTER(1 ..));
            column(ReportForNavId_4; 4) { } // Autogenerated by ForNav - Do not delete
        }
    }
    requestpage
    {
        SaveValues = false;
        layout
        {
            area(Content)
            {
                group(Scanpan)
                {
                    Caption = 'Scanpan';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Basic;
                        Caption = 'Start date';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Basic;
                        Caption = 'End date';
                    }
                }
                group(Options)
                {
                    Caption = 'Options';
                    field(ForNavOpenDesigner; ReportForNavOpenDesigner)
                    {
                        ApplicationArea = Basic;
                        Caption = 'Design';
                        Visible = ReportForNavAllowDesign;
                    }
                }
            }
        }

    }
    var
        CountryRegion: Record "Country/Region";
        LineNo: Integer;
        StartingDate: Date;
        EndingDate: Date;

    trigger OnInitReport()
    begin
        ;
        ReportsForNavInit;

    end;

    trigger OnPostReport()
    begin
        ;
        ReportForNav.Post;
    end;

    trigger OnPreReport()
    begin
        ;
        ReportsForNavPre;
        //"Cust. Ledger Entry".SetFilter("Posting Date",'%1..%2', StartingDate,EndingDate);
    end;

    // --> Reports ForNAV Autogenerated code - do not delete or modify
    var
        [WithEvents]
        ReportForNav: DotNet ForNavReport50014_v7_2_0_2471;
        ReportForNavOpenDesigner: Boolean;
        [InDataSet]
        ReportForNavAllowDesign: Boolean;

    local procedure ReportsForNavInit();
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
        addInFileName: Text;
        tempAddInFileName: Text;
        path: DotNet System_IO_Path50014;
        ReportForNavObject: Variant;
    begin
        addInFileName := ApplicationPath() + 'Add-ins\ReportsForNAV_7_2_0_2471\ForNav.Reports.7.2.0.2471.dll';
        if not File.Exists(addInFileName) then begin
            tempAddInFileName := path.GetTempPath() + '\Microsoft Dynamics NAV\Add-Ins\' + ApplicationSystemConstants.PlatformFileVersion() + '\ForNav.Reports.7.2.0.2471.dll';
            if not File.Exists(tempAddInFileName) then
                Error('Please install the ForNAV DLL version 7.2.0.2471 in your service tier Add-ins folder under the file name "%1"\\If you already have the ForNAV DLL on the server, you should move it to this folder and rename it to match this file name.', addInFileName);
        end;
        ReportForNavObject := ReportForNav.GetLatest(CurrReport.OBJECTID, CurrReport.Language, SerialNumber, UserId, CompanyName);
        ReportForNav := ReportForNavObject;
        ReportForNav.Init();
    end;

    local procedure ReportsForNavPre();
    begin
        ReportForNav.OpenDesigner := ReportForNavOpenDesigner;
        if not ReportForNav.Pre() then CurrReport.Quit();
    end;

    // Reports ForNAV Autogenerated code - do not delete or modify -->
}
