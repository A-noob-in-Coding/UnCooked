#!/usr/bin/env python3
"""Build GroupX.pdf for FAST DevOps submission. No hyphens or dashes in prose."""
from __future__ import annotations

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm, mm
from reportlab.platypus import (
    Image,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "UnCooked.pdf"
SS = ROOT / "images" / "final_ss"
P0 = ROOT / "images" / "P0"
P0_ISSUES = P0 / "issues"


def nodash(text: str) -> str:
    """Remove hyphen and dash characters from display text (keep URL path chars elsewhere)."""
    for ch in ("\u2014", "\u2013", "\u2212", "\u2010", "\u2011", "-", "–", "—"):
        text = text.replace(ch, " ")
    while "  " in text:
        text = text.replace("  ", " ")
    return text.strip()


def style_sheet():
    s = getSampleStyleSheet()
    s.add(ParagraphStyle(name="CoverTitle", parent=s["Title"], fontSize=22, spaceAfter=12, alignment=TA_CENTER))
    s.add(ParagraphStyle(name="H", parent=s["Heading1"], fontSize=14, spaceBefore=14, spaceAfter=8))
    s.add(ParagraphStyle(name="H2", parent=s["Heading2"], fontSize=12, spaceBefore=10, spaceAfter=6))
    s.add(ParagraphStyle(name="Body", parent=s["BodyText"], fontSize=10, leading=14, alignment=TA_JUSTIFY, spaceAfter=6))
    s.add(ParagraphStyle(name="Small", parent=s["BodyText"], fontSize=8, leading=10, textColor=colors.grey))
    s.add(ParagraphStyle(name="Cap", parent=s["BodyText"], fontSize=9, leading=11, alignment=TA_CENTER, spaceAfter=10))
    return s


def link(url: str, label: str | None = None) -> str:
    shown = label or url
    return f'<link href="{url}" color="blue"><u>{shown}</u></link>'


def add_img(story, path: Path, styles, caption: str, max_w=16.5 * cm, max_h=10 * cm):
    cap = nodash(caption)
    if not path.exists():
        story.append(Paragraph(nodash(f"[missing {path.name}]"), styles["Small"]))
        return
    img = Image(str(path))
    iw, ih = img.imageWidth, img.imageHeight
    scale = min(max_w / iw, max_h / ih, 1.0)
    img.drawWidth = iw * scale
    img.drawHeight = ih * scale
    story.append(KeepTogether([img, Paragraph(cap, styles["Cap"])]))


def main():
    styles = style_sheet()
    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=1.6 * cm,
        rightMargin=1.6 * cm,
        topMargin=1.4 * cm,
        bottomMargin=1.4 * cm,
        title=nodash("UnCooked DevOps Final Project"),
        author="BSE 7B Group",
    )
    story = []

    story.append(Paragraph(nodash("DevOps Final Project UnCooked.pdf"), styles["CoverTitle"]))
    story.append(Paragraph(nodash("UnCooked FAST NU Lahore Fall 2026 BSE 7B"), styles["Cap"]))
    story.append(Paragraph(nodash("Instructor Durraiz Waseem  TA Malahim Chaudhary"), styles["Cap"]))
    story.append(Spacer(1, 8 * mm))

    members = [
        [nodash("Name"), nodash("Roll number")],
        [nodash("Muhammad Ahmad Butt"), "23L 3059"],
        [nodash("Ali Ahmed"), "23L 3067"],
        [nodash("Muhammad Zain Tahir"), "23L 3078"],
    ]
    t = Table(members, colWidths=[9 * cm, 5 * cm])
    t.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#1a1a1a")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 10),
                ("GRID", (0, 0), (-1, -1), 0.4, colors.grey),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.whitesmoke, colors.white]),
                ("PADDING", (0, 0), (-1, -1), 6),
            ]
        )
    )
    story.append(t)
    story.append(Spacer(1, 8 * mm))
    story.append(
        Paragraph(
            "<b>GitHub:</b> " + link("https://github.com/m-ahmad-butt/UnCooked", "github.com/m ahmad butt/UnCooked"),
            styles["Body"],
        )
    )
    story.append(
        Paragraph(
            "<b>Live app:</b> "
            + link(
                "http://uncooked-alb-1680261338.ap-south-1.elb.amazonaws.com",
                "uncooked ALB (ap south 1)",
            ),
            styles["Body"],
        )
    )
    story.append(
        Paragraph(
            nodash(
                "Region ap south 1. Stack: VPC public and private in 2 AZs, ALB, ASG min 2, data EC2, ECR, "
                "GitHub OIDC CD, CloudWatch alarms, SSM (SSH closed)."
            ),
            styles["Body"],
        )
    )

    story.append(PageBreak())
    story.append(Paragraph(nodash("1. Architecture diagram"), styles["H"]))
    story.append(
        Paragraph(
            nodash(
                "Request path: Internet to ALB (public subnets) to App ASG in private subnets "
                "(frontend backend agent) to data EC2 (Mongo Redis Rabbit). Private egress via NAT. "
                "CI stages 02 to 10 on push/PR. CD 11 to 12 on main via OIDC to ECR to SSM rolling deploy "
                "to smoke to auto rollback. Secrets in GitHub Secrets and SSM. CloudWatch alarms on ALB 5xx "
                "and unhealthy hosts."
            ),
            styles["Body"],
        )
    )
    arch_png = ROOT / "docs" / "architecture.png"
    if arch_png.exists():
        add_img(story, arch_png, styles, "Figure 1 AWS and pipeline overview", max_h=12 * cm)
    else:
        story.append(
            Paragraph(
                nodash("Vector diagram lives in docs/architecture.svg. Overview:"),
                styles["Body"],
            )
        )
        story.append(
            Paragraph(
                "<font face='Courier' size='8'>"
                + nodash(
                    "Internet to ALB (public) to ASG apps (private 2 AZ) "
                    "to Data EC2 (private). NAT for ECR and SSM. "
                    "GitHub Actions CI 02 to 10 / CD 11 to 12 OIDC to ECR to SSM"
                )
                + "</font>",
                styles["Body"],
            )
        )

    story.append(Paragraph(nodash("2. Short findings report"), styles["H"]))
    story.append(
        Paragraph(
            nodash(
                "We learned that DevSecOps only works when scanners are required checks and HA includes "
                "self healing bootstrap, not just two instances. Main pain points: Sonar Snyk Trivy merge "
                "blocks (fixed or accepted in SECURITY.md), OIDC trust subject mismatch, and ALB 502 after "
                "ASG replace because empty Ubuntu boxes lacked Docker/app until launch template self heal "
                "was added. Moving apps into private subnets with NAT closed the networking gap in the brief."
            ),
            styles["Body"],
        )
    )
    story.append(Paragraph(nodash("Post incident (short)"), styles["H2"]))
    story.append(
        Paragraph(
            nodash(
                "After terminating both app instances, ASG launched replacements but the site stayed 502 until "
                "containers existed. Root cause: user data did not install or run the app. Fix: bootstrap Docker, "
                "read image tag and JWT from SSM, pull ECR, compose up; grace 900s. Verify: one instance terminate "
                "then auto healthy then ALB 200. Detail: docs/post incident.md."
            ),
            styles["Body"],
        )
    )
    contrib = [
        [nodash("Name"), nodash("Roll"), nodash("Contributions")],
        [nodash("Muhammad Ahmad Butt"), "23L 3059", nodash("CI/CD, Terraform HA, deploy smoke rollback, evidence")],
        [nodash("Ali Ahmed"), "23L 3067", nodash("AWS ops, ECR OIDC checks, load HA demos, screenshots")],
        [nodash("Muhammad Zain Tahir"), "23L 3078", nodash("App services, Compose, local docs, PR reviews")],
    ]
    ct = Table(contrib, colWidths=[4.2 * cm, 2.6 * cm, 9.5 * cm])
    ct.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#222")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("GRID", (0, 0), (-1, -1), 0.3, colors.grey),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("PADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    story.append(ct)

    story.append(PageBreak())
    story.append(Paragraph(nodash("3. Phase 01 issues (security blockers)"), styles["H"]))
    story.append(
        Paragraph(
            nodash(
                "Evidence that security stages failed and blocked work until fixed. "
                "Full notes: images/P0/issues/fix.txt"
            ),
            styles["Body"],
        )
    )
    phase01_issues = [
        (P0_ISSUES / "Sonar-cube-error.png", "Phase 01 SonarCloud quality gate failed"),
        (P0_ISSUES / "Snyk-error.png", "Phase 01 Snyk high critical finding"),
        (P0_ISSUES / "Snyk-error-02.png", "Phase 01 Snyk finding (2)"),
        (P0_ISSUES / "Snyk-error-03.png", "Phase 01 Snyk finding (3)"),
    ]
    for path, cap in phase01_issues:
        add_img(story, path, styles, cap)

    story.append(Paragraph(nodash("Phase 01 Dependabot and branch protection"), styles["H2"]))
    for path, cap in [
        (P0 / "P0-dep-bots.png", "Dependabot enabled"),
        (P0 / "branch-protection-01.png", "Branch protection settings (1)"),
        (P0 / "branch-protection-02.png", "Branch protection settings (2)"),
        (P0 / "branch-protection-03.png", "Branch protection settings (3)"),
    ]:
        add_img(story, path, styles, cap)

    story.append(PageBreak())
    story.append(Paragraph(nodash("4. Proof of deployment (Phase 02 screenshots)"), styles["H"]))
    story.append(
        Paragraph(
            nodash("Selected evidence from images/final_ss. Full set lives in the repository."),
            styles["Body"],
        )
    )

    shots = [
        (SS / "01-s3.png", "S3 Terraform state (private)"),
        (SS / "02-dynamo-db-lock.png", "DynamoDB state lock"),
        (SS / "03a-vpc.png", "VPC"),
        (SS / "03b-subnets.png", "Multi AZ subnets"),
        (SS / "04-alb.png", "Application Load Balancer"),
        (SS / "05-asg.png", "Auto Scaling Group (min 2)"),
        (SS / "06-ec2.png", "EC2 app and data"),
        (SS / "07-ecr-aws.png", "ECR immutable repos"),
        (SS / "08-oidc-trust.png", "IAM OIDC trust for GitHub"),
        (SS / "09-ci-pass.png", "CI stages as separate jobs"),
        (SS / "10-ci-block.png", "Security stage blocked PR"),
        (SS / "11a-branch-protection.png", "Branch protection (1)"),
        (SS / "11b-branch-protection.png", "Branch protection (2)"),
        (SS / "11c-branch-protection.png", "Branch protection (3)"),
        (SS / "12-cd-pass.png", "CD ECR push and deploy smoke"),
        (SS / "13-live-app.png", "Live app via ALB"),
        (SS / "14a-terminate-ec2.png", "Failure demo terminate instance"),
        (SS / "14b-auto-creation.png", "ASG auto replace"),
        (SS / "15a-load-test.png", "Load test (Apache Bench)"),
        (SS / "15b-load-test.png", "Load test metrics"),
        (SS / "16a-alarm.png", "CloudWatch alarms"),
        (SS / "16b-alb-alarm.png", "ALB 5xx alarm"),
        (SS / "16c-health-alarm.png", "Unhealthy hosts alarm"),
        (SS / "17-rollback.png", "Manual rollback workflow"),
    ]
    for path, cap in shots:
        add_img(story, path, styles, cap)

    story.append(Paragraph(nodash("5. How to run and tear down"), styles["H"]))
    story.append(
        Paragraph(
            nodash(
                "Local: cd web then docker compose up --build. "
                "Cloud: Terraform apply (see README and docs/PHASE02.md), set GitHub OIDC secret and vars, "
                "SSM JWT, merge to main for CD. Tear down: cd terraform then terraform destroy. "
                "Leave bootstrap state if needed. Set budget_email in terraform.tfvars."
            ),
            styles["Body"],
        )
    )

    doc.build(story)
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
