enum 50023 "SPN StdCost Wksh Status"
{
    ///<summary>
    /// Standard Cost Worksheet Status Enumeration
    /// Defines the lifecycle states of a standard cost worksheet.
    ///
    /// Change Log:
    /// 2025.10    Jesper Harder    116.1    SPN SKU Std. Cost Worksheet – create draft from locked SKUs 
    ///                                      implement (preserve fixed costs)
    /// </summary>

    Extensible = false;

    /// <summary>
    /// Draft status - worksheet is being prepared and can be modified.
    /// Lines can be added, edited, or deleted in this state.
    /// </summary>
    value(0; Draft) 
    { 
        Caption = 'Draft'; 
    }

    /// <summary>
    /// Implemented status - worksheet has been applied and SKU standard costs have been updated.
    /// No further modifications are allowed in this state to preserve audit trail.
    /// </summary>
    value(1; Implemented) 
    { 
        Caption = 'Implemented'; 
    }
}
