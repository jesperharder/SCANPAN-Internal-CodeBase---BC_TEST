


codeunit 50004 "TEST_CU"
{

    Access = Public;
    Subtype = Normal;

    trigger OnRun()
    begin
        DeleteFullyInvoicedPurchaseOrders();
    end;

    var
VareHouseShipmentLine: Record "Warehouse Shipment Line";




    #region Delete invoiced IIC Purchaseorders
    /// <summary>
    /// DeleteFullyInvoicedPurchaseOrders.
    /// </summary>
    procedure DeleteFullyInvoicedPurchaseOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        TestMsg: Text;
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        if not PurchaseHeader.FindSet() then
            exit;

        repeat
            if IsReadyForDeletion(PurchaseHeader."No.") then
                TestMsg += 'Yes -' + PurchaseHeader."No." + '\'
            else
                TestMsg += 'No  -' + PurchaseHeader."No." + '\';
        until PurchaseHeader.Next() = 0;
        Message(TestMsg);
    end;


    local procedure IsReadyForDeletion(PurchaseOrderNo: code[20]): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        IsReadyDelete: Boolean;
        TestCompanyLbl: Label 'This must be executed from Scanpan Norway Company. ';
        CompanyNameDK: Text[100];
        CompanyNameNO: Text[100];
        VendorOrderNo: Code[35];
    begin
        IsReadyDelete := true;
        CompanyNameDK := 'SCANPAN Danmark';
        CompanyNameNO := 'SCANPAN Norge';
        if CompanyName <> CompanyNameNO then error(TestCompanyLbl + CompanyName);

        //Test if DropShip linked salesorder exists Norway
        PurchaseLine.Reset();
        PurchaseLine.SetFilter("Document Type", '%1', PurchaseLine."Document Type"::Order);
        PurchaseLine.SetFilter("Document No.", PurchaseOrderNo);
        PurchaseLine.SetFilter(Type, '%1', PurchaseLine.Type::Item);
        PurchaseLine.SetFilter("Drop Shipment", '%1', true);
        if not PurchaseLine.FindFirst() then
            exit;

        //Test if IIC linked salesorder exists Denmark
        if not PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseOrderNo) then
            exit;
        VendorOrderNo := PurchaseHeader."Vendor Order No.";

        if VendorOrderNo = '' then
            exit;

        SalesHeader.ChangeCompany(CompanyNameDK);
        if SalesHeader.Get(SalesHeader."Document Type"::Order, VendorOrderNo) then
            IsReadyDelete := false;

        exit(IsReadyDelete);
    end;
    #endregion


}