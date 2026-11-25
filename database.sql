-- جدول المستخدمين
CREATE TABLE users (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    username VARCHAR(50) UNIQUE,
    email VARCHAR(100),
    password VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user',
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول صلاحيات المستخدمين
CREATE TABLE user_permissions (
    user_id VARCHAR(50) PRIMARY KEY,
    can_edit BOOLEAN DEFAULT FALSE,
    can_delete BOOLEAN DEFAULT FALSE,
    sections TEXT, -- يمكن تخزين الأقسام المسموحة كـ JSON
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- جدول الأصناف (المخزون)
CREATE TABLE items (
    id VARCHAR(50) PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    barcode VARCHAR(100),
    name VARCHAR(200) NOT NULL,
    category VARCHAR(100),
    cost DECIMAL(10, 2) DEFAULT 0,
    price DECIMAL(10, 2) DEFAULT 0,
    stock INT DEFAULT 0,
    unit VARCHAR(30), -- وحدة البيع (حبة، كرتون، كيلو...)
    expiry_date DATE, -- تاريخ انتهاء الصلاحية
    offer_price DECIMAL(10, 2), -- سعر العرض المؤقت
    offer_until DATE, -- تاريخ انتهاء العرض
    date_added TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول العملاء
CREATE TABLE customers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    tax_number VARCHAR(50),
    trade_name VARCHAR(200),
    building_no VARCHAR(20),
    street VARCHAR(200),
    district VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country_code VARCHAR(5) DEFAULT 'SA',
    balance DECIMAL(12, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول الموردين
CREATE TABLE suppliers (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    tax_number VARCHAR(50),
    trade_name VARCHAR(200),
    balance DECIMAL(12, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول الموظفين
CREATE TABLE employees (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    national_id VARCHAR(50),
    nationality VARCHAR(50),
    phone VARCHAR(50),
    address TEXT,
    basic_salary DECIMAL(12, 2) DEFAULT 0, -- الراتب الساري (نسخة عرض من سجل الرواتب)
    salary_effective_from DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول الصناديق والحسابات
CREATE TABLE funds (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(15, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول الفواتير (مبيعات، مشتريات، مرتجعات، عروض أسعار)
CREATE TABLE invoices (
    id VARCHAR(50) PRIMARY KEY,
    serial VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL, -- sales, purchase, sales_return, purchase_return, quote, purchase_order
    date DATE NOT NULL,
    entity_id VARCHAR(50), -- ID of customer or supplier
    total DECIMAL(12, 2) DEFAULT 0,
    vat_total DECIMAL(12, 2) DEFAULT 0,
    net_total DECIMAL(12, 2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'draft',
    notes TEXT,
    party_vat_number VARCHAR(50), -- الرقم الضريبي للعميل/المورد وقت الفاتورة
    party_trade_name VARCHAR(200), -- الاسم التجاري للعميل/المورد
    party_address TEXT, -- عنوان العميل/المورد
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول تفاصيل الفواتير (الأصناف داخل الفاتورة)
CREATE TABLE invoice_items (
    id VARCHAR(50) PRIMARY KEY,
    invoice_id VARCHAR(50) NOT NULL,
    item_id VARCHAR(50) NOT NULL,
    qty INT DEFAULT 1,
    price DECIMAL(10, 2) DEFAULT 0,
    cost DECIMAL(10, 2) DEFAULT 0,
    total DECIMAL(12, 2) DEFAULT 0,
    vat DECIMAL(10, 2) DEFAULT 0,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES items(id)
);

-- جدول السندات (قبض وصرف)
CREATE TABLE vouchers (
    id VARCHAR(50) PRIMARY KEY,
    serial VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(20) NOT NULL, -- receipt, payment
    entity_type VARCHAR(20), -- customer, supplier, employee, tender, general
    entity_id VARCHAR(50),
    fund_id VARCHAR(50),
    category VARCHAR(100),
    date DATE NOT NULL,
    amount DECIMAL(12, 2) DEFAULT 0,
    notes TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    salary_details TEXT, -- JSON for salary breakdown if applicable
    is_tax_note BOOLEAN DEFAULT FALSE, -- إشعار مدين/دائن ضريبي (زاتكا)
    orig_invoice_id VARCHAR(50),
    net_amount DECIMAL(12, 2) DEFAULT 0,
    tax_amount DECIMAL(12, 2) DEFAULT 0,
    reason TEXT,
    note_type_id VARCHAR(50), -- نوع إشعار الموظف
    advance_id VARCHAR(50), -- السلفة المرتبطة
    advance_ref VARCHAR(10), -- disburse | collect | reverse | cancel
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fund_id) REFERENCES funds(id)
);

-- جدول المصروفات
CREATE TABLE expenses (
    id VARCHAR(50) PRIMARY KEY,
    serial VARCHAR(50) UNIQUE,
    date DATE NOT NULL,
    type VARCHAR(100),
    amount DECIMAL(12, 2) DEFAULT 0,
    notes TEXT,
    status VARCHAR(20) DEFAULT 'draft',
    fund_id VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fund_id) REFERENCES funds(id)
);

-- جدول المناقصات
CREATE TABLE tenders (
    id VARCHAR(50) PRIMARY KEY,
    serial VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(200) NOT NULL,
    entity_name VARCHAR(100),
    date DATE NOT NULL,
    deadline DATE,
    status VARCHAR(20) DEFAULT 'open',
    insurance_amount DECIMAL(12, 2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول سجل النسخ الاحتياطي
CREATE TABLE backups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    file_name VARCHAR(255) NOT NULL,
    backup_type VARCHAR(50) NOT NULL, -- local, cloud
    file_size VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- جدول الإعدادات
CREATE TABLE settings (
    id INT PRIMARY KEY DEFAULT 1,
    company_name VARCHAR(100),
    company_address TEXT,
    company_phone VARCHAR(50),
    tax_number VARCHAR(50),
    vat_percent DECIMAL(5, 2) DEFAULT 15,
    currency VARCHAR(20) DEFAULT 'ر.س',
    inventory_name VARCHAR(50) DEFAULT 'المخزون',
    funds_name VARCHAR(50) DEFAULT 'الصناديق والحسابات',
    language VARCHAR(10) DEFAULT 'ar',
    invoice_color VARCHAR(20) DEFAULT '#4f46e5',
    show_logo BOOLEAN DEFAULT TRUE,
    show_tax_number BOOLEAN DEFAULT TRUE,
    footer_text TEXT,
    terms_and_conditions TEXT,
    expiry_alert_days INT DEFAULT 30,
    price_check_enabled BOOLEAN DEFAULT TRUE, -- شاشة استعلام الأسعار
    price_check_in_menu BOOLEAN DEFAULT TRUE,
    price_check_public BOOLEAN DEFAULT TRUE,
    price_check_vat_inclusive BOOLEAN DEFAULT TRUE,
    price_check_show_offers BOOLEAN DEFAULT TRUE,
    price_check_show_stock BOOLEAN DEFAULT FALSE,
    price_check_show_wholesale BOOLEAN DEFAULT FALSE,
    price_check_idle_seconds INT DEFAULT 15,
    price_check_welcome TEXT
);

-- ===================== الربط مع هيئة الزكاة (زاتكا) =====================
CREATE TABLE zatca_settings (
    id INT PRIMARY KEY DEFAULT 1,
    environment VARCHAR(20) DEFAULT 'production',
    seller_name VARCHAR(200),
    vat_number VARCHAR(20),
    crn VARCHAR(20),
    street VARCHAR(200),
    building_no VARCHAR(20),
    district VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    egs_serial VARCHAR(100),
    auto_send BOOLEAN DEFAULT FALSE,
    auto_from_at TIMESTAMP,
    private_key_pem TEXT,
    csr_pem TEXT,
    compliance_csid TEXT,
    compliance_secret TEXT,
    production_csid TEXT,
    production_secret TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE zatca_chain (
    id INT PRIMARY KEY DEFAULT 1,
    last_icv INT DEFAULT 0,
    last_pih TEXT
);

CREATE TABLE zatca_documents (
    id VARCHAR(80) PRIMARY KEY,
    source_type VARCHAR(30) NOT NULL, -- sales_invoice, sales_return, sales_tax_note
    source_id VARCHAR(50) NOT NULL,
    invoice_number VARCHAR(50),
    uuid VARCHAR(50),
    icv INT,
    invoice_hash TEXT,
    pih TEXT,
    qr TEXT,
    xml_signed TEXT,
    status VARCHAR(30), -- CLEARED, REPORTED, WARNING, REJECTED, ERROR
    response TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (source_type, source_id)
);

CREATE TABLE zatca_connection_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action VARCHAR(50),
    http_status INT,
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================== إرسال واتساب =====================
CREATE TABLE wa_settings (
    id INT PRIMARY KEY DEFAULT 1,
    country VARCHAR(5),
    prefer_app BOOLEAN DEFAULT FALSE,
    template_statement TEXT,
    template_invoice TEXT
);

CREATE TABLE wa_numbers (
    party_type VARCHAR(20) NOT NULL, -- customer, supplier
    party_id VARCHAR(50) NOT NULL,
    number VARCHAR(20),
    PRIMARY KEY (party_type, party_id)
);

CREATE TABLE wa_log (
    id VARCHAR(50) PRIMARY KEY,
    party_type VARCHAR(20),
    party_id VARCHAR(50),
    party_name VARCHAR(200),
    number VARCHAR(20),
    kind VARCHAR(30), -- statement, invoice, order
    ref VARCHAR(100),
    message TEXT,
    method VARCHAR(20),
    user_name VARCHAR(100),
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===================== إدارة علاقات العملاء (CRM) =====================
CREATE TABLE crm_profiles (
    customer_id VARCHAR(50) PRIMARY KEY,
    classification VARCHAR(50),
    source VARCHAR(100),
    owner VARCHAR(100),
    tags TEXT,
    birthday DATE,
    credit_limit DECIMAL(12, 2) DEFAULT 0,
    notes TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE crm_contacts (
    id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    title VARCHAR(100),
    mobile VARCHAR(50),
    email VARCHAR(100),
    birthday DATE,
    is_primary BOOLEAN DEFAULT FALSE,
    notes TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE crm_leads (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    company VARCHAR(200),
    mobile VARCHAR(50),
    email VARCHAR(100),
    city VARCHAR(100),
    source VARCHAR(100),
    interest TEXT,
    estimated_value DECIMAL(12, 2) DEFAULT 0,
    status VARCHAR(30) DEFAULT 'جديد',
    owner VARCHAR(100),
    next_date DATE,
    lost_reason TEXT,
    converted_customer_id VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE crm_followups (
    id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    lead_id VARCHAR(50),
    opp_id VARCHAR(50),
    due_date DATE NOT NULL,
    type VARCHAR(30),
    subject TEXT,
    owner VARCHAR(100),
    status VARCHAR(20) DEFAULT 'مفتوحة',
    result TEXT,
    done_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE crm_opportunities (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    customer_id VARCHAR(50),
    stage VARCHAR(30) NOT NULL,
    value DECIMAL(12, 2) DEFAULT 0,
    probability INT DEFAULT 0,
    expected_date DATE,
    owner VARCHAR(100),
    source VARCHAR(100),
    lost_reason TEXT,
    quote_id VARCHAR(50),
    invoice_id VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE crm_opp_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    opp_id VARCHAR(50) NOT NULL,
    from_stage VARCHAR(30),
    to_stage VARCHAR(30),
    user_name VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (opp_id) REFERENCES crm_opportunities(id) ON DELETE CASCADE
);

CREATE TABLE crm_activities (
    id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    lead_id VARCHAR(50),
    opp_id VARCHAR(50),
    type VARCHAR(30),
    summary TEXT,
    outcome VARCHAR(100),
    user_name VARCHAR(100),
    activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE crm_tickets (
    id VARCHAR(50) PRIMARY KEY,
    number VARCHAR(30) UNIQUE,
    customer_id VARCHAR(50),
    invoice_id VARCHAR(50),
    subject VARCHAR(200),
    description TEXT,
    category VARCHAR(50),
    priority VARCHAR(20),
    status VARCHAR(20) DEFAULT 'مفتوحة',
    owner VARCHAR(100),
    resolution TEXT,
    due_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE crm_campaigns (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    channel VARCHAR(30),
    segment VARCHAR(50),
    message TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE crm_campaign_targets (
    campaign_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    mobile VARCHAR(50),
    status VARCHAR(20) DEFAULT 'لم يُرسل',
    sent_at TIMESTAMP,
    PRIMARY KEY (campaign_id, customer_id),
    FOREIGN KEY (campaign_id) REFERENCES crm_campaigns(id) ON DELETE CASCADE
);

CREATE TABLE crm_targets (
    id VARCHAR(50) PRIMARY KEY,
    owner VARCHAR(100) NOT NULL,
    period VARCHAR(7) NOT NULL, -- YYYY-MM
    sales_target DECIMAL(12, 2) DEFAULT 0,
    calls_target INT DEFAULT 0,
    deals_target INT DEFAULT 0,
    UNIQUE (owner, period)
);

-- ══════════════ شؤون الموظفين: أنواع الإشعارات، سجل الرواتب، السلف بالأقساط ══════════════

-- أنواع حسابات إشعارات الموظفين (دائن: رواتب، عمولات... / مدين: خصم تأخير، غياب...)
CREATE TABLE hr_note_types (
    id VARCHAR(50) PRIMARY KEY,
    kind VARCHAR(10) NOT NULL CHECK (kind IN ('credit', 'debit')),
    name VARCHAR(100) NOT NULL,
    account_code VARCHAR(20) NOT NULL, -- الحساب في شجرة الحسابات (يظهر بقائمة الدخل)
    builtin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    UNIQUE (kind, name)
);

-- سجل الرواتب: كل تغيير سجل جديد يُغلق السابق (لا تداخل فترات)
CREATE TABLE employee_salary_history (
    id VARCHAR(50) PRIMARY KEY,
    employee_id VARCHAR(50) NOT NULL,
    basic_salary DECIMAL(12, 2) NOT NULL CHECK (basic_salary >= 0),
    effective_from DATE NOT NULL,
    effective_to DATE, -- NULL = الفترة السارية
    reason TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (employee_id, effective_from),
    CHECK (effective_to IS NULL OR effective_to >= effective_from),
    FOREIGN KEY (employee_id) REFERENCES employees(id)
);
CREATE INDEX idx_salary_history_emp ON employee_salary_history (employee_id, effective_from);

-- سلف الموظفين
CREATE TABLE employee_advances (
    id VARCHAR(50) PRIMARY KEY,
    advance_number VARCHAR(30) NOT NULL UNIQUE, -- ADV-00001 (تلقائي)
    employee_id VARCHAR(50) NOT NULL,
    request_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    frequency VARCHAR(10) NOT NULL CHECK (frequency IN ('monthly', 'weekly', 'custom', 'single')),
    installments_count INT NOT NULL,
    installment_amount DECIMAL(12, 2) NOT NULL,
    first_due_date DATE NOT NULL,
    status VARCHAR(10) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'cancelled')),
    account_code VARCHAR(20), -- حساب السلف وقت الصرف
    fund_id VARCHAR(50),
    disburse_voucher_id VARCHAR(50) UNIQUE,
    disbursed_at DATE,
    approved_by VARCHAR(100),
    cancel_voucher_id VARCHAR(50) UNIQUE,
    cancelled_by VARCHAR(100),
    cancelled_at DATE,
    cancel_reason TEXT,
    reason TEXT,
    notes TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (fund_id) REFERENCES funds(id),
    FOREIGN KEY (disburse_voucher_id) REFERENCES vouchers(id),
    FOREIGN KEY (cancel_voucher_id) REFERENCES vouchers(id)
);
CREATE INDEX idx_adv_employee ON employee_advances (employee_id, status);
CREATE INDEX idx_adv_date ON employee_advances (request_date);

-- أقساط السلف
CREATE TABLE employee_advance_installments (
    id VARCHAR(50) PRIMARY KEY,
    advance_id VARCHAR(50) NOT NULL,
    seq INT NOT NULL,
    due_date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    rescheduled_out DECIMAL(12, 2) DEFAULT 0, -- ما نُقل منه عند التعديل/إعادة الجدولة
    is_postponed BOOLEAN DEFAULT FALSE,
    original_due_date DATE,
    is_cancelled BOOLEAN DEFAULT FALSE,
    notes TEXT,
    updated_at TIMESTAMP,
    UNIQUE (advance_id, seq),
    FOREIGN KEY (advance_id) REFERENCES employee_advances(id) ON DELETE CASCADE
);
CREATE INDEX idx_adv_inst_due ON employee_advance_installments (due_date);

-- ربط سندات القبض بالأقساط (لا يتكرر نفس السند مع نفس القسط)
CREATE TABLE employee_advance_payments (
    id VARCHAR(50) PRIMARY KEY,
    advance_id VARCHAR(50) NOT NULL,
    installment_id VARCHAR(50) NOT NULL,
    voucher_id VARCHAR(50) NOT NULL,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    pay_date DATE NOT NULL,
    is_reversed BOOLEAN DEFAULT FALSE,
    reversal_voucher_id VARCHAR(50),
    reversed_at TIMESTAMP,
    reversed_by VARCHAR(100),
    reverse_reason TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (voucher_id, installment_id),
    FOREIGN KEY (advance_id) REFERENCES employee_advances(id),
    FOREIGN KEY (installment_id) REFERENCES employee_advance_installments(id),
    FOREIGN KEY (voucher_id) REFERENCES vouchers(id),
    FOREIGN KEY (reversal_voucher_id) REFERENCES vouchers(id)
);
CREATE INDEX idx_adv_pay_advance ON employee_advance_payments (advance_id);
CREATE INDEX idx_adv_pay_voucher ON employee_advance_payments (voucher_id);

-- سجل تدقيق السلف (إنشاء، صرف، تحصيل، تأجيل، تعديل، إعادة جدولة، عكس، إلغاء)
CREATE TABLE employee_advance_audit (
    id VARCHAR(50) PRIMARY KEY,
    advance_id VARCHAR(50) NOT NULL,
    action VARCHAR(50) NOT NULL,
    details TEXT,
    reason TEXT,
    user_name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (advance_id) REFERENCES employee_advances(id)
);
CREATE INDEX idx_adv_audit ON employee_advance_audit (advance_id, created_at);

-- إعدادات السلف (حساب السلف من الشجرة والصندوق الافتراضي)
CREATE TABLE employee_advance_settings (
    id VARCHAR(50) PRIMARY KEY, -- 'settings'
    account_code VARCHAR(20),
    default_fund_id VARCHAR(50),
    FOREIGN KEY (default_fund_id) REFERENCES funds(id)
);

-- الأنواع الافتراضية (حساباتها ضمن شجرة الحسابات النظامية)
INSERT INTO hr_note_types (id, kind, name, account_code, builtin) VALUES
    ('nt-salaries', 'credit', 'رواتب', '5220', TRUE),
    ('nt-commissions', 'credit', 'عمولات', '5261', TRUE),
    ('nt-allowances', 'credit', 'بدلات', '5262', TRUE),
    ('nt-overtime', 'credit', 'إضافي', '5263', TRUE),
    ('nt-incentives', 'credit', 'حوافز', '5264', TRUE),
    ('nt-late', 'debit', 'خصم تأخير', '4241', TRUE),
    ('nt-absence', 'debit', 'خصم غياب', '4242', TRUE),
    ('nt-unpaid-leave', 'debit', 'خصم إجازة بدون إذن', '4243', TRUE);
