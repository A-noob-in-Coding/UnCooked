import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import {
  Document,
  Packer,
  Paragraph,
  TextRun,
  Table,
  TableRow,
  TableCell,
  WidthType,
  HeadingLevel,
  PageBreak,
  ImageRun,
  ExternalHyperlink,
  AlignmentType,
  BorderStyle,
  ShadingType,
  Header,
  Footer,
  PageNumber,
} from "docx";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const OUT = path.join(ROOT, "UnCooked.docx");
const SS = path.join(ROOT, "images", "final_ss");
const P0 = path.join(ROOT, "images", "P0");
const P0_ISSUES = path.join(P0, "issues");

function nodash(t) {
  return String(t)
    .replace(/[\u2010-\u2015\u2212\-–—]/g, " ")
    .replace(/ {2,}/g, " ")
    .trim();
}

function p(text, opts = {}) {
  return new Paragraph({
    spacing: { after: 120 },
    alignment: opts.align,
    ...opts,
    children: [
      new TextRun({
        text: nodash(text),
        font: "Arial",
        size: opts.size || 20,
        bold: opts.bold,
      }),
    ],
  });
}

function h1(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    spacing: { before: 280, after: 140 },
    children: [new TextRun({ text: nodash(text), font: "Arial", size: 28, bold: true })],
  });
}

function h2(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 200, after: 100 },
    children: [new TextRun({ text: nodash(text), font: "Arial", size: 24, bold: true })],
  });
}

function cell(text, opts = {}) {
  return new TableCell({
    width: { size: opts.width || 3000, type: WidthType.DXA },
    shading: opts.header
      ? { type: ShadingType.CLEAR, fill: "1A1A1A" }
      : undefined,
    children: [
      new Paragraph({
        children: [
          new TextRun({
            text: nodash(text),
            font: "Arial",
            size: opts.size || 18,
            bold: !!opts.header || !!opts.bold,
            color: opts.header ? "FFFFFF" : "000000",
          }),
        ],
      }),
    ],
  });
}

function linkPara(label, url, shown) {
  return new Paragraph({
    spacing: { after: 120 },
    children: [
      new TextRun({ text: nodash(label) + " ", font: "Arial", size: 20, bold: true }),
      new ExternalHyperlink({
        children: [
          new TextRun({
            text: nodash(shown),
            font: "Arial",
            size: 20,
            color: "0563C1",
            underline: {},
          }),
        ],
        link: url,
      }),
    ],
  });
}

function imgBlock(filePath, caption, maxWidth = 540) {
  if (!fs.existsSync(filePath)) {
    return [p(`[missing ${path.basename(filePath)}]`, { size: 16 })];
  }
  const buf = fs.readFileSync(filePath);
  const ext = path.extname(filePath).toLowerCase();
  const type = ext === ".jpg" || ext === ".jpeg" ? "jpg" : "png";
  // keep aspect roughly; docx needs width/height
  let width = maxWidth;
  let height = Math.round(maxWidth * 0.58);
  try {
    // PNG IHDR width/height at bytes 16-23
    if (type === "png" && buf.length > 24) {
      const w = buf.readUInt32BE(16);
      const h = buf.readUInt32BE(20);
      if (w > 0 && h > 0) {
        height = Math.round((maxWidth * h) / w);
        if (height > 420) {
          height = 420;
          width = Math.round((420 * w) / h);
        }
      }
    }
  } catch {
    /* keep defaults */
  }
  return [
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 120, after: 60 },
      children: [
        new ImageRun({
          type,
          data: buf,
          transformation: { width, height },
        }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { after: 200 },
      children: [
        new TextRun({ text: nodash(caption), font: "Arial", size: 16, italics: true, color: "444444" }),
      ],
    }),
  ];
}

const thin = { style: BorderStyle.SINGLE, size: 4, color: "999999" };
const borders = { top: thin, bottom: thin, left: thin, right: thin };

function memberTable() {
  const rows = [
    ["Name", "Roll number"],
    ["Muhammad Ahmad Butt", "23L 3059"],
    ["Ali Ahmed", "23L 3067"],
    ["Muhammad Zain Tahir", "23L 3078"],
  ].map((r, i) =>
    new TableRow({
      children: [
        cell(r[0], { width: 5500, header: i === 0 }),
        cell(r[1], { width: 3500, header: i === 0 }),
      ],
    })
  );
  return new Table({
    width: { size: 9000, type: WidthType.DXA },
    columnWidths: [5500, 3500],
    rows,
  });
}

function contribTable() {
  const data = [
    ["Name", "Roll", "Contributions"],
    ["Muhammad Ahmad Butt", "23L 3059", "CI/CD, Terraform HA, deploy smoke rollback, evidence"],
    ["Ali Ahmed", "23L 3067", "AWS ops, ECR OIDC checks, load HA demos, screenshots"],
    ["Muhammad Zain Tahir", "23L 3078", "App services, Compose, local docs, PR reviews"],
  ];
  return new Table({
    width: { size: 9000, type: WidthType.DXA },
    columnWidths: [2800, 1600, 4600],
    rows: data.map(
      (r, i) =>
        new TableRow({
          children: [
            cell(r[0], { width: 2800, header: i === 0, size: 16 }),
            cell(r[1], { width: 1600, header: i === 0, size: 16 }),
            cell(r[2], { width: 4600, header: i === 0, size: 16 }),
          ],
        })
    ),
  });
}

const children = [];

children.push(
  new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: { after: 200 },
    children: [
      new TextRun({ text: nodash("DevOps Final Project UnCooked.docx"), font: "Arial", size: 36, bold: true }),
    ],
  }),
  p("UnCooked FAST NU Lahore Fall 2026 BSE 7B", { align: AlignmentType.CENTER, size: 20 }),
  p("Instructor Durraiz Waseem  TA Malahim Chaudhary", { align: AlignmentType.CENTER, size: 18 }),
  new Paragraph({ spacing: { after: 200 }, children: [] }),
  memberTable(),
  new Paragraph({ spacing: { after: 200 }, children: [] }),
  linkPara("GitHub:", "https://github.com/m-ahmad-butt/UnCooked", "github.com/m ahmad butt/UnCooked"),
  linkPara(
    "Live app:",
    "http://uncooked-alb-1680261338.ap-south-1.elb.amazonaws.com",
    "uncooked ALB (ap south 1)"
  ),
  p(
    "Region ap south 1. Stack: VPC public and private in 2 AZs, ALB, ASG min 2, data EC2, ECR, GitHub OIDC CD, CloudWatch alarms, SSM (SSH closed)."
  )
);

children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("1. Architecture diagram"),
  p(
    "Request path: Internet to ALB (public subnets) to App ASG in private subnets (frontend backend agent) to data EC2 (Mongo Redis Rabbit). Private egress via NAT. CI stages 02 to 10 on push/PR. CD 11 to 12 on main via OIDC to ECR to SSM rolling deploy to smoke to auto rollback. Secrets in GitHub Secrets and SSM. CloudWatch alarms on ALB 5xx and unhealthy hosts."
  ),
  p("Vector diagram lives in docs/architecture.svg. Overview:"),
  p(
    "Internet to ALB (public) to ASG apps (private 2 AZ) to Data EC2 (private). NAT for ECR and SSM. GitHub Actions CI 02 to 10 / CD 11 to 12 OIDC to ECR to SSM",
    { size: 16 }
  ),
  h1("2. Short findings report"),
  p(
    "We learned that DevSecOps only works when scanners are required checks and HA includes self healing bootstrap, not just two instances. Main pain points: Sonar Snyk Trivy merge blocks (fixed or accepted in SECURITY.md), OIDC trust subject mismatch, and ALB 502 after ASG replace because empty Ubuntu boxes lacked Docker/app until launch template self heal was added. Moving apps into private subnets with NAT closed the networking gap in the brief."
  ),
  h2("Post incident (short)"),
  p(
    "After terminating both app instances, ASG launched replacements but the site stayed 502 until containers existed. Root cause: user data did not install or run the app. Fix: bootstrap Docker, read image tag and JWT from SSM, pull ECR, compose up; grace 900s. Verify: one instance terminate then auto healthy then ALB 200. Detail: docs/post incident.md."
  ),
  contribTable()
);

children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("3. Phase 01 issues (security blockers)"),
  p("Evidence that security stages failed and blocked work until fixed. Full notes: images/P0/issues/fix.txt"),
  ...imgBlock(path.join(P0_ISSUES, "Sonar-cube-error.png"), "Phase 01 SonarCloud quality gate failed"),
  ...imgBlock(path.join(P0_ISSUES, "Snyk-error.png"), "Phase 01 Snyk high critical finding"),
  ...imgBlock(path.join(P0_ISSUES, "Snyk-error-02.png"), "Phase 01 Snyk finding (2)"),
  ...imgBlock(path.join(P0_ISSUES, "Snyk-error-03.png"), "Phase 01 Snyk finding (3)"),
  h2("Phase 01 Dependabot and branch protection"),
  ...imgBlock(path.join(P0, "P0-dep-bots.png"), "Dependabot enabled"),
  ...imgBlock(path.join(P0, "branch-protection-01.png"), "Branch protection settings (1)"),
  ...imgBlock(path.join(P0, "branch-protection-02.png"), "Branch protection settings (2)"),
  ...imgBlock(path.join(P0, "branch-protection-03.png"), "Branch protection settings (3)")
);

const phase02 = [
  ["01-s3.png", "S3 Terraform state (private)"],
  ["02-dynamo-db-lock.png", "DynamoDB state lock"],
  ["03a-vpc.png", "VPC"],
  ["03b-subnets.png", "Multi AZ subnets"],
  ["04-alb.png", "Application Load Balancer"],
  ["05-asg.png", "Auto Scaling Group (min 2)"],
  ["06-ec2.png", "EC2 app and data"],
  ["07-ecr-aws.png", "ECR immutable repos"],
  ["08-oidc-trust.png", "IAM OIDC trust for GitHub"],
  ["09-ci-pass.png", "CI stages as separate jobs"],
  ["10-ci-block.png", "Security stage blocked PR"],
  ["11a-branch-protection.png", "Branch protection (1)"],
  ["11b-branch-protection.png", "Branch protection (2)"],
  ["11c-branch-protection.png", "Branch protection (3)"],
  ["12-cd-pass.png", "CD ECR push and deploy smoke"],
  ["13-live-app.png", "Live app via ALB"],
  ["14a-terminate-ec2.png", "Failure demo terminate instance"],
  ["14b-auto-creation.png", "ASG auto replace"],
  ["15a-load-test.png", "Load test (Apache Bench)"],
  ["15b-load-test.png", "Load test metrics"],
  ["16a-alarm.png", "CloudWatch alarms"],
  ["16b-alb-alarm.png", "ALB 5xx alarm"],
  ["16c-health-alarm.png", "Unhealthy hosts alarm"],
  ["17-rollback.png", "Manual rollback workflow"],
];

children.push(
  new Paragraph({ children: [new PageBreak()] }),
  h1("4. Proof of deployment (Phase 02 screenshots)"),
  p("Selected evidence from images/final_ss. Full set lives in the repository.")
);
for (const [file, cap] of phase02) {
  children.push(...imgBlock(path.join(SS, file), cap));
}

children.push(
  h1("5. How to run and tear down"),
  p(
    "Local: cd web then docker compose up --build. Cloud: Terraform apply (see README and docs/PHASE02.md), set GitHub OIDC secret and vars, SSM JWT, merge to main for CD. Tear down: cd terraform then terraform destroy. Leave bootstrap state if needed. Set budget_email in terraform.tfvars."
  )
);

const doc = new Document({
  styles: {
    default: {
      document: {
        styles: [{ id: "Normal", run: { font: "Arial", size: 20 } }],
      },
      heading1: {
        run: { font: "Arial", size: 28, bold: true },
        paragraph: { spacing: { before: 280, after: 140 }, keepNext: true },
      },
      heading2: {
        run: { font: "Arial", size: 24, bold: true },
        paragraph: { spacing: { before: 200, after: 100 }, keepNext: true },
      },
    },
  },
  sections: [
    {
      properties: {
        page: {
          margin: { top: 720, bottom: 720, left: 720, right: 720 },
        },
      },
      headers: {
        default: new Header({
          children: [
            new Paragraph({
              children: [
                new TextRun({ text: nodash("UnCooked DevOps Final  BSE 7B"), font: "Arial", size: 16, color: "666666" }),
              ],
            }),
          ],
        }),
      },
      footers: {
        default: new Footer({
          children: [
            new Paragraph({
              alignment: AlignmentType.CENTER,
              children: [
                new TextRun({ text: "Page ", font: "Arial", size: 16 }),
                new TextRun({ children: [PageNumber.CURRENT], font: "Arial", size: 16 }),
              ],
            }),
          ],
        }),
      },
      children,
    },
  ],
});

const buf = await Packer.toBuffer(doc);
fs.writeFileSync(OUT, buf);
console.log("Wrote", OUT);
