#pragma warning disable AA0005, AA0008, AA0018, AA0021, AA0072, AA0137, AA0201, AA0206, AA0218, AA0228, AL0254, AL0424, AS0011, AW0006 // ForNAV settings
dotnet // --> Reports ForNAV Autogenerated code - do not delete or modify
{
    assembly("ForNav.Reports.7.0.0.2350")
    {
        type(ForNav.Report_7_0_0_2350; ForNavReport50010_v7_0_0_2350) { }
    }
} // Reports ForNAV Autogenerated code - do not delete or modify -->

/// <summary>
/// Report Ordrebeholdning 50010 (ID 50010).
/// </summary>
Report 50010 "Ordrebeholdning"
{
    AdditionalSearchTerms = 'Scanpan';

    caption = 'Order Inventory';
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/layout/Ordrebeholdning50010.rdlc';

    dataset
    {
        dataitem("Company Information"; "Company Information")
        {
            column(ReportForNavId_3; 3) { } // Autogenerated by ForNav - Do not delete
        }
        dataitem("Sales Line"; "Sales Line")
        {
#pragma warning disable AL0603 // TODO: - Kan ikke få :: til at virke her
            DataItemTableView = sorting("Document Type", "Document No.", Type, "Line No.") where("Document Type" = CONST(1));
#pragma warning restore AL0603 // TODO: - Kan ikke få :: til at virke her
            column(ReportForNavId_1; 1) { } // Autogenerated by ForNav - Do not delete
            column(ReportCaptionName; ReportCaptionName)
            {
                IncludeCaption = false;
            }
            column(LanguageSelected; LanguageSelectedCode)
            {
                IncludeCaption = false;
            }
            column(ReportLanguageCode; ReportLanguageCodeCode)
            {
                IncludeCaption = false;
            }
            column(ItemTranslationText; ItemTranslationText)
            {
                IncludeCaption = false;
            }
            dataitem("Sales Header"; "Sales Header")
            {
                DataItemLink = "Document Type" = FIELD("Document Type"), "No." = FIELD("Document No.");
                DataItemTableView = sorting("Document Type", "No.") where("Document Type" = CONST(Order));
                RequestFilterFields = "No.", "Sell-to Customer No.", "External Document No.", "Shipment Date";
                column(ReportForNavId_2; 2) { } // Autogenerated by ForNav - Do not delete
            }
            trigger OnAfterGetRecord();
            var
                sl: Record "Sales Line";
            begin
                ItemTranslationText := LookupItemTranslation("Sales Line"."No.", LanguageSelectedCode);
            end;

        }
    }

    requestpage
    {

        SaveValues = false;
        layout
        {
            area(content)
            {
                group(Scanpan)
                {
                    Caption = 'Scanpan';
                    label(explainer)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '** To export;choose Excel(data and layout)';
                    }
                    field(ReportLanguageOption; ReportLanguageOptionOpt)
                    {
                        ApplicationArea = Basic;
                        //Caption = 'Select report language';
                        Caption = 'Report Caption Language';
                        OptionCaption = 'Dansk,English';
                    }

                    field(LanguageSelected; LanguageSelectedCode)
                    {
                        ApplicationArea = Basic;
                        //Caption = 'Sprog';
                        Caption = 'Item language';
                        TableRelation = Language.Code;

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            rLanguage: Record Language;
                        begin
                            rLanguage.SetFilter(Code, 'DEU|DAN|ENU|NOR|FIN|FRA|NLD|SVE|BEL');
                            if page.RunModal(Page::Languages, rLanguage) = Action::LookupOK then LanguageSelectedCode := rLanguage.Code;

                        end;
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

        actions
        {
        }
    }

    trigger OnInitReport()
    begin
        ;
        ReportsForNavInit;

    end;

    trigger OnPreReport()
    begin
        //Language
        ReportLanguageCodeCode := 'ENU';
        ReportCaptionName := 'Order status';
        IF ReportLanguageOptionOpt = 0 THEN begin
            ReportLanguageCodeCode := 'DAN';
            ReportCaptionName := 'Ordrebeholdning';
        end;

        //CurrReport.LANGUAGE := ReportLanguage.GetLanguageID(ReportLanguageCode);

        CurrReport.LANGUAGE := LanguageCU.GetLanguageID(ReportLanguageCodeCode);

        ReportsForNavPre;
    end;

    trigger OnPostReport()
    begin
        ;
        ReportForNav.Post;
    end;

    var
        //TABLES
        //ReportLanguage: Record Language;
        LanguageCU: Codeunit Language;
        ReportLanguageCodeCode: Code[10];
        //VARIABLES
        LanguageSelectedCode: Code[20];
        ReportLanguageOptionOpt: Option;
        ReportCaptionName: Text[50];
        ItemTranslationText: Text[200];

    // --> Reports ForNAV Autogenerated code - do not delete or modify
    var
        [InDataSet]
        ReportForNavAllowDesign: Boolean;
        ReportForNavOpenDesigner: Boolean;
        [WithEvents]
        ReportForNav: DotNet ForNavReport50010_v7_0_0_2350;

    local procedure LookupItemTranslation(ItemNo: code[20]; LanguageID: code[20]): Text[200];
    var
        ItemTranslation: Record "Item Translation";
    begin
        ItemTranslation.SetFilter("Item No.", ItemNo);
        ItemTranslation.SetFilter("Language Code", LanguageID);
        if ItemTranslation.FindFirst() then
            exit(ItemTranslation.Description) else
            exit("Sales Line".Description);


    end;

    local procedure ReportsForNavInit();
    var
        ApplicationSystemConstants: Codeunit "Application System Constants";
        path: DotNet Path;
        addInFileName: Text;
        tempAddInFileName: Text;
        ReportForNavObject: Variant;
    begin
        addInFileName := ApplicationPath() + 'Add-ins\ReportsForNAV_7_0_0_2350\ForNav.Reports.7.0.0.2350.dll';
        if not File.Exists(addInFileName) then begin
            tempAddInFileName := path.GetTempPath() + '\Microsoft Dynamics NAV\Add-Ins\' + ApplicationSystemConstants.PlatformFileVersion() + '\ForNav.Reports.7.0.0.2350.dll';
            if not File.Exists(tempAddInFileName) then
                Error('Please install the ForNAV DLL version 7.0.0.2350 in your service tier Add-ins folder under the file name "%1"\\If you already have the ForNAV DLL on the server, you should move it to this folder and rename it to match this file name.', addInFileName);
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
