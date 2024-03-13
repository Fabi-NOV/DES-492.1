/*
-- BSP Data & BI Solutions --

-- Revision History --
REV00: This is the first release of this code.
REV01:
    Inclusion of Count calculations to control transactions
    Inclusion of Quantity Recalculation, based on Operation Status
	Ajuste do cálculo Controle Retorno

-- Notes --
-- Relatório Movimentação via TPMG: Saída e Retorno

*/

select 
--tprem.ORGANIZATION_ID
org.NAME                                Org
,tprem.TRX_NUMBER                       NF_Saida
,to_date(tprem.TRX_DATE,'DD/MM/RRRR')   Data_NF_Saida
,to_date(tprem.SEFAZ_AUTHORIZATION_DATE,'DD/MM/RRRR')   Data_SEFAZ
,to_date(tprem.RETURN_DATE,'DD/MM/RRRR')    Data_Retorno_Limite
,tprem.SOURCE_CODE
,cta.SO
,cta.SO_Type
,MSI.ITEM
,MSI.DESCRIPTION   
--,tprem.ITEM_DESCRIPTION
,tprem.SHIPPED_QUANTITY
--,DECODE(tpret.OPERATION_STATUS,'INCOMPLETE',0,
--        tprem.SHIPPED_QUANTITY) SHIPPED_QUANTITY_RECALC        
,tprem.SUBINVENTORY
--,tprem.LOCATOR_ID
,LOC.LOCATOR
,tprem.LOT_NUMBER
,tprem.SERIAL_NUMBER
,tprem.UNIT_PRICE
,tprem.CANCEL_FLAG
,tprem.REMAINING_BALANCE
,DECODE(tpret.OPERATION_STATUS,'INCOMPLETE',0,
        tprem.REMAINING_BALANCE)        REMAINING_BALANCE_RECALC
,tprem.SOURCE_SUBINVENTORY
--,tprem.SOURCE_LOCATOR_ID
,tprem.ERROR_FLAG
,tpret.OPERATION_ID                 RI_Retorno
,tpret.OPERATION_STATUS
,(CASE
WHEN tpret.OPERATION_STATUS='INCOMPLETE' AND tpret.RETURNED_DATE <= Last_Day(add_months(sysdate,-1)) THEN 'Operacao Bloqueada'
WHEN tpret.OPERATION_STATUS='INCOMPLETE' AND tpret.RETURNED_DATE > Last_Day(add_months(sysdate,-1)) THEN 'Revisar Operacao'
WHEN NVL(tpret.OPERATION_STATUS,'x')='x' THEN 'Sem Retorno' 
ELSE 'Ok'
END) STATUS_RETORNO
--,DECODE(tpret.OPERATION_STATUS,'INCOMPLETE',
--        'Revisar Operação','Ok') STATUS_RETORNO
,DECODE(INSTR(tpret.INVOICE_NUMBER,'.'),0,tpret.INVOICE_NUMBER,
        SUBSTR(tpret.INVOICE_NUMBER,1,(INSTR(tpret.INVOICE_NUMBER,'.')-1)))               NF_Retorno
,tpret.ITEM_NUMBER
,to_date(tpret.INVOICE_DATE,'DD/MM/RRRR')                   Data_NF_Retorno
,to_date(tpret.RETURNED_DATE,'DD/MM/RRRR')                  Data_Retorno
--,tpret.INVENTORY_ITEM_ID
,tpret.RETURNED_QUANTITY
,DECODE(tpret.OPERATION_STATUS,'INCOMPLETE',0,
        tpret.RETURNED_QUANTITY)    RETURNED_QUANTITY_RECALC

,tpret.NEW_SUBINVENTORY
--,tpret.NEW_LOCATOR_ID
--,tpret.UNIT_PRICE
--,tpret.AVAILABLE_FOR_RETURN
,tprem.TPA_REMIT_CONTROL_ID
,tprem.ORG_ID
,tprem.CUST_TRX_TYPE_ID
,tprem.CUSTOMER_TRX_ID
,tprem.CUSTOMER_TRX_LINE_ID
,tprem.DELIVERY_DETAIL_ID
,tpret.TPA_RETURN_CONTROL_ID
--,tpret.TPA_REMIT_CONTROL_ID
,tpret.SHIP_TO_SITE_USE_ID
,tpret.ENTITY_ID
,tpret.INVOICE_ID
,tpret.INVOICE_LINE_ID
,tpret.RETURNED_TRANSACTION_ID
,tprem.TRANSFER_ORGANIZATION_ID
,tprem.INVENTORY_ITEM_ID
, COUNT (tprem.LOT_NUMBER) OVER (PARTITION BY tprem.LOT_NUMBER) As Count_Lot_Remit
, COUNT (tprem.LOT_NUMBER) OVER (PARTITION BY tprem.LOT_NUMBER,tpret.OPERATION_STATUS) As Count_Lot_Return
,(
CASE
WHEN NVL(tpret.RETURNED_QUANTITY,0)=0 AND NVL(tpret.RETURNED_TRANSACTION_ID,0)<>0 THEN 'Disregard'
WHEN NVL(tpret.RETURNED_QUANTITY,0)=0 AND NVL(tpret.RETURNED_TRANSACTION_ID,0)=0  THEN 'Sem Retorno'
ELSE 'Ok'
END)as Return_Control

from 
    apps.CLL_F513_TPA_REMIT_CONTROL tprem

left join (select ORGANIZATION_ID,OPERATION_ID,OPERATION_STATUS,INVOICE_NUMBER,ITEM_NUMBER,INVOICE_DATE,RETURNED_DATE,INVENTORY_ITEM_ID,RETURNED_QUANTITY,NEW_SUBINVENTORY
            ,NEW_LOCATOR_ID,UNIT_PRICE,AVAILABLE_FOR_RETURN,TPA_REMIT_CONTROL_ID,TPA_RETURN_CONTROL_ID,SHIP_TO_SITE_USE_ID,ENTITY_ID,
            INVOICE_ID,INVOICE_LINE_ID,RETURNED_TRANSACTION_ID,REVERSION_FLAG from apps.CLL_F513_TPA_RETURNS_CONTROL where REVERSION_FLAG IS NULL)tpret
            ON tprem.ORGANIZATION_ID           =   tpret.ORGANIZATION_ID
            AND tprem.TPA_REMIT_CONTROL_ID      =   tpret.TPA_REMIT_CONTROL_ID



left join (select INVENTORY_ITEM_ID,ORGANIZATION_ID,SEGMENT1 AS ITEM,DESCRIPTION from MTL_SYSTEM_ITEMS_B
            where ORGANIZATION_ID=4226) MSI
            ON tprem.ORGANIZATION_ID    =   MSI.ORGANIZATION_ID
            AND tprem.INVENTORY_ITEM_ID =   MSI.INVENTORY_ITEM_ID

left join (select MIL.ORGANIZATION_ID,MIL.INVENTORY_LOCATION_ID,DECODE (NVL(PPA.PROJECT,'x'),'x',MIL.SEGMENT1,(MIL.SEGMENT1||'|'||PPA.PROJECT)) AS LOCATOR  from MTL_ITEM_LOCATIONS MIL 
            left join (select PROJECT_ID,SEGMENT1 AS PROJECT from PA_PROJECTS_ALL) PPA
                        ON MIL.PROJECT_ID   =   PPA.PROJECT_ID
                        where MIL.ORGANIZATION_ID=4226)LOC
            ON tprem.ORGANIZATION_ID    =   LOC.ORGANIZATION_ID
            AND tprem.LOCATOR_ID        =   LOC.INVENTORY_LOCATION_ID
            
left join (select ORGANIZATION_ID, NAME from HR_ALL_ORGANIZATION_UNITS
            where ORGANIZATION_ID=4226)org
           ON  tprem.ORGANIZATION_ID    =   org.ORGANIZATION_ID

left join (select CUSTOMER_TRX_ID,INTERFACE_HEADER_ATTRIBUTE1 AS SO,INTERFACE_HEADER_ATTRIBUTE2 AS SO_Type,CT_REFERENCE,ORG_ID from RA_CUSTOMER_TRX_ALL)cta
            ON tprem.CUSTOMER_TRX_ID     =   cta.CUSTOMER_TRX_ID
            AND tprem.ORG_ID             =   cta.ORG_ID
        
where
1=1
and tprem.ORGANIZATION_ID=4226

--and tpret.INVOICE_NUMBER='26532'
--and tprem.LOT_NUMBER='ACU47490120'

--and tprem.TRX_NUMBER in ('19590','19595')

