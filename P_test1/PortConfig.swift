//
//  PortConfig.swift
//  P_test1
//
//  Created by Assistant on 2/16/26.
//

import Foundation
import SwiftUI

/// Model representing a port configuration with the specified keys.
struct PortConfig: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let applicationRootUrl: String
    let apiRootUrl: String
    let mainAppUrl: String
    let ocpRootUrl: String

    init(id: UUID = UUID(), name: String, applicationRootUrl: String, apiRootUrl: String, mainAppUrl: String, ocpRootUrl: String) {
        self.id = id
        self.name = name
        self.applicationRootUrl = applicationRootUrl
        self.apiRootUrl = apiRootUrl
        self.mainAppUrl = mainAppUrl
        self.ocpRootUrl = ocpRootUrl
    }

    /// Returns a deterministic color per config for consistent UI appearance.
    var stableColor: Color {
        // Hash the name to pick a color from a fixed palette.
        let palette: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .brown
        ]
        let idx = abs(name.hashValue) % palette.count
        return palette[idx].opacity(0.2)
    }

    /// JSON representation of the config matching the required keys only.
    var jsonString: String {
        struct Payload: Codable {
            let applicationRootUrl: String
            let apiRootUrl: String
            let mainAppUrl: String
            let ocpRootUrl: String
        }
        let payload = Payload(
            applicationRootUrl: applicationRootUrl,
            apiRootUrl: apiRootUrl,
            mainAppUrl: mainAppUrl,
            ocpRootUrl: ocpRootUrl
        )
        let encoder = JSONEncoder()
        if #available(iOS 15.0, macOS 12.0, *) {
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = [.prettyPrinted]
        }
        if let data = try? encoder.encode(payload), let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{}"
    }
}

extension PortConfig {
    /// Sample ports to drive the UI. Add or modify as needed.
    static let samples: [PortConfig] = [
        PortConfig(
            name: "G8Tab",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/g8mobile/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/g8restapi/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/g8tab/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/g8ocp/"
        ),
        PortConfig(
            name: "SAML PORT - ocpclientgold8sql",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/mobile/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/restapidotnet/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/tab/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/ocpclientgold8sql/"
        ),
        PortConfig(
            name: "IOB-SIT",
            applicationRootUrl: "https://crmsit.iob.in/mobile/",
            apiRootUrl: "https://crmsit.iob.in/restapi2/",
            mainAppUrl: "https://crmsit.iob.in/app/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "SBI_G7",
            applicationRootUrl: "https://uat.crm.sbi.co.in/apk7/mobile/",
            apiRootUrl: "https://uat.crm.sbi.co.in/apk7/CRMnextRestAPI/",
            mainAppUrl: "https://uat.crm.sbi.co.in/apk7/tab/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "GA-SQL",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/gasqlmobile/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/gasqlrestapi/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/gasqlmobile/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/ocpclientgold8sql/"
        ),
        PortConfig(
            name: "SBIGOLD7_SA",
            applicationRootUrl: "https://b147.businessbywire.com/sbigold7_sa/mobile/",
            apiRootUrl: "https://b147.businessbywire.com/sbigold7_sa/CRMnextRestAPI/",
            mainAppUrl: "https://b147.businessbywire.com/sbigold7_sa/tab/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "gold8appsql",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/gold8mobilesql/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/gold8restapisql/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/gold8appsql/MobileSettings/GenerateQRCode/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/ocpclientgold8sql/"
        ),
        PortConfig(
            name: "IOB-SIT-ALT",
            applicationRootUrl: "https://crmsit.iob.in/mobile/",
            apiRootUrl: "https://crmsit.iob.in/restapi2/",
            mainAppUrl: "https://crmsit.iob.in/app/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "PMLI-UAT",
            applicationRootUrl: "https://crm.uat.pnbmetlife.com/mobilepmli/",
            apiRootUrl: "https://crm.uat.pnbmetlife.com/restapipmli/",
            mainAppUrl: "http://atyourservice-app.apps.uat.pmli.corp/apppm/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "gold8tabsql",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/gold8mobilesql/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/gold8restapisql/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/gold8tabsql/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/ocpclientgold8sql/"
        ),
        PortConfig(
            name: "mobile7ora",
            applicationRootUrl: "https://s4.businessbywire.com/mobile7ora/",
            apiRootUrl: "https://s4.businessbywire.com/restapi7ora/",
            mainAppUrl: "https://s4.businessbywire.com/app7ora/login/login",
            ocpRootUrl: "http://s4.businessbywire.com/identityserver7ora "
        ),
        PortConfig(
            name: "gold8tabora",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/gold8mobileora/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/gold8restapiora/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/gold8tabora/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/gold8ocpora/"
        ),
        PortConfig(
            name: "tabnpgs",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/mobilenpgs/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/restapinpgs/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/tabnpgs/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/ocpclientpostgressql1/"
        ),
        PortConfig(
            name: "SALES-restapisales",
            applicationRootUrl: "https://b22.businessbywire.com/mobilesales/",
            apiRootUrl: "https://b22.businessbywire.com/restapisales/",
            mainAppUrl: "https://b22.businessbywire.com/appsales/MobileSettings/GenerateQRCode/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "DEMO-tabdemo",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/mobiledemo/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/restapidemo/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/tabdemo/",
            ocpRootUrl: ""
        ),
        PortConfig(
            name: "app03ora",
            applicationRootUrl: "https://b18.businessbywire.com/mobile03ora/",
            apiRootUrl: "https://b18.businessbywire.com/restapi03ora/",
            mainAppUrl: "https://b18.businessbywire.com/app03ora/MobileSettings/GenerateQRCode/",
            ocpRootUrl: "https://b18.businessbywire.com/ocpclient03ora/"
        ),
        PortConfig(
            name: "GOLD8-gold8tabsql",
            applicationRootUrl: "https://qag.businessnext.crmnextlab.com/gold8mobilesql/",
            apiRootUrl: "https://qag.businessnext.crmnextlab.com/gold8restapisql/",
            mainAppUrl: "https://qag.businessnext.crmnextlab.com/gold8tabsql/",
            ocpRootUrl: "https://qag.businessnext.crmnextlab.com/ocpclientgold8sql/"
        ),
        PortConfig(
            name: "restapi03ora",
            applicationRootUrl: "https://b18.businessbywire.com/mobile03ora/",
            apiRootUrl: "https://b18.businessbywire.com/restapi03ora/",
            mainAppUrl: "https://b18.businessbywire.com/app03ora/MobileSettings/GenerateQRCode/",
            ocpRootUrl: "https://b18.businessbywire.com/ocpclient03ora/"
        )
    ]
}
